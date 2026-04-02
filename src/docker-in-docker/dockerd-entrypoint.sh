#!/bin/sh
set -eu

_tls_ensure_private() {
	local f="$1"; shift
	[ -s "$f" ] || openssl genrsa -out "$f" 4096
}
_tls_san() {
	{
		ip -oneline address | awk '{ gsub(/\/.+$/, "", $4); print "IP:" $4 }'
		{
			cat /etc/hostname
			echo 'docker'
			echo 'localhost'
			hostname -f
			hostname -s
		} | sed 's/^/DNS:/'
		[ -z "${DOCKER_TLS_SAN:-}" ] || echo "$DOCKER_TLS_SAN"
	} | sort -u | xargs printf '%s,' | sed 's/,$//'
}
_tls_generate_certs() {
	local dir="$1"; shift

	if [ -s "$dir/server/ca.pem" ] && [ -s "$dir/server/cert.pem" ] && [ -s "$dir/server/key.pem" ] && [ ! -s "$dir/ca/key.pem" ]; then
		openssl verify -CAfile "$dir/server/ca.pem" "$dir/server/cert.pem"
		return 0
	fi

	local certValidDays='825'

	if [ -s "$dir/ca/key.pem" ] || [ ! -s "$dir/ca/cert.pem" ]; then
		mkdir -p "$dir/ca"
		_tls_ensure_private "$dir/ca/key.pem"
		openssl req -new -key "$dir/ca/key.pem" \
			-out "$dir/ca/cert.pem" \
			-subj '/CN=docker:dind CA' \
			-x509 \
			-days "$certValidDays" \
			-addext keyUsage=critical,digitalSignature,keyCertSign
	fi

	if [ -s "$dir/ca/key.pem" ]; then
		mkdir -p "$dir/server"
		_tls_ensure_private "$dir/server/key.pem"
		openssl req -new -key "$dir/server/key.pem" \
			-out "$dir/server/csr.pem" \
			-subj '/CN=docker:dind server'
		cat > "$dir/server/openssl.cnf" <<-EOF
			[ x509_exts ]
			extendedKeyUsage = serverAuth
			subjectAltName = $(_tls_san)
		EOF
		openssl x509 -req \
				-in "$dir/server/csr.pem" \
				-CA "$dir/ca/cert.pem" \
				-CAkey "$dir/ca/key.pem" \
				-CAcreateserial \
				-out "$dir/server/cert.pem" \
				-days "$certValidDays" \
				-extfile "$dir/server/openssl.cnf" \
				-extensions x509_exts
		cp "$dir/ca/cert.pem" "$dir/server/ca.pem"
		openssl verify -CAfile "$dir/server/ca.pem" "$dir/server/cert.pem"
	fi

	if [ -s "$dir/ca/key.pem" ]; then
		mkdir -p "$dir/client"
		_tls_ensure_private "$dir/client/key.pem"
		chmod 0644 "$dir/client/key.pem"
		openssl req -new \
				-key "$dir/client/key.pem" \
				-out "$dir/client/csr.pem" \
				-subj '/CN=docker:dind client'
		cat > "$dir/client/openssl.cnf" <<-'EOF'
			[ x509_exts ]
			extendedKeyUsage = clientAuth
		EOF
		openssl x509 -req \
				-in "$dir/client/csr.pem" \
				-CA "$dir/ca/cert.pem" \
				-CAkey "$dir/ca/key.pem" \
				-CAcreateserial \
				-out "$dir/client/cert.pem" \
				-days "$certValidDays" \
				-extfile "$dir/client/openssl.cnf" \
				-extensions x509_exts
		cp "$dir/ca/cert.pem" "$dir/client/ca.pem"
		openssl verify -CAfile "$dir/client/ca.pem" "$dir/client/cert.pem"
	fi
}

if [ "$#" -eq 0 ] || [ "${1#-}" != "$1" ]; then
	uid="$(id -u)"
	if [ "$uid" = '0' ]; then
		dockerSocket='unix:///var/run/docker.sock'
	else
		: "${XDG_RUNTIME_DIR:=/run/user/$uid}"
		dockerSocket="unix://$XDG_RUNTIME_DIR/docker.sock"
	fi
	case "${DOCKER_HOST:-}" in
		unix://*)
			dockerSocket="$DOCKER_HOST"
			;;
	esac

	if [ -n "${DOCKER_TLS_CERTDIR:-}" ]; then
		_tls_generate_certs "$DOCKER_TLS_CERTDIR"
		set -- dockerd \
			--host="$dockerSocket" \
			--host=tcp://0.0.0.0:2376 \
			--tlsverify \
			--tlscacert "$DOCKER_TLS_CERTDIR/server/ca.pem" \
			--tlscert "$DOCKER_TLS_CERTDIR/server/cert.pem" \
			--tlskey "$DOCKER_TLS_CERTDIR/server/key.pem" \
			"$@"
		DOCKERD_ROOTLESS_ROOTLESSKIT_FLAGS="${DOCKERD_ROOTLESS_ROOTLESSKIT_FLAGS:-} -p 0.0.0.0:2376:2376/tcp"
	else
		set -- dockerd \
			--host="$dockerSocket" \
			--host=tcp://0.0.0.0:2375 \
			"$@"
		DOCKERD_ROOTLESS_ROOTLESSKIT_FLAGS="${DOCKERD_ROOTLESS_ROOTLESSKIT_FLAGS:-} -p 0.0.0.0:2375:2375/tcp"
	fi
fi

if [ "$1" = 'dockerd' ]; then
	find /run /var/run -iname 'docker*.pid' -delete || :

	set -- docker-init -- "$@"

	iptablesLegacy=
	if [ -n "${DOCKER_IPTABLES_LEGACY+x}" ]; then
		iptablesLegacy="$DOCKER_IPTABLES_LEGACY"
		if [ -n "$iptablesLegacy" ]; then
			modprobe ip_tables || :
			modprobe ip6_tables || :
		else
			modprobe nf_tables || :
		fi
	elif (
		for f in /proc/net/ip_tables_names /proc/net/ip6_tables_names /proc/net/arp_tables_names; do
			if b="$(cat "$f")" && [ -n "$b" ]; then
				exit 0
			fi
		done
		exit 1
	); then
		iptablesLegacy=1
	elif ! iptables -nL > /dev/null 2>&1; then
		modprobe nf_tables || :
		if ! iptables -nL > /dev/null 2>&1; then
			modprobe ip_tables || :
			modprobe ip6_tables || :
			if /usr/local/sbin/.iptables-legacy/iptables -nL > /dev/null 2>&1; then
				iptablesLegacy=1
			fi
		fi
	fi
	if [ -n "$iptablesLegacy" ]; then
		export PATH="/usr/local/sbin/.iptables-legacy:$PATH"
	fi
	iptables --version

	uid="$(id -u)"
	if [ "$uid" != '0' ]; then
		if ! command -v rootlesskit > /dev/null; then
			echo >&2 "error: attempting to run rootless dockerd but missing 'rootlesskit'"
			exit 1
		fi
		user="$(id -un 2>/dev/null || :)"
		if ! grep -qE "^($uid${user:+|$user}):" /etc/subuid || ! grep -qE "^($uid${user:+|$user}):" /etc/subgid; then
			echo >&2 "error: attempting to run rootless dockerd but missing necessary entries in /etc/subuid and/or /etc/subgid for $uid"
			exit 1
		fi
		: "${XDG_RUNTIME_DIR:=/run/user/$uid}"
		export XDG_RUNTIME_DIR
		if ! mkdir -p "$XDG_RUNTIME_DIR" || [ ! -w "$XDG_RUNTIME_DIR" ] || ! mkdir -p "$HOME/.local/share/docker" || [ ! -w "$HOME/.local/share/docker" ]; then
			echo >&2 "error: attempting to run rootless dockerd but need writable HOME ($HOME) and XDG_RUNTIME_DIR ($XDG_RUNTIME_DIR) for user $uid"
			exit 1
		fi
		if [ -f /proc/sys/kernel/unprivileged_userns_clone ] && unprivClone="$(cat /proc/sys/kernel/unprivileged_userns_clone)" && [ "$unprivClone" != '1' ]; then
			echo >&2 "error: attempting to run rootless dockerd but need 'kernel.unprivileged_userns_clone' set to 1"
			exit 1
		fi
		if [ -f /proc/sys/user/max_user_namespaces ] && maxUserns="$(cat /proc/sys/user/max_user_namespaces)" && [ "$maxUserns" = '0' ]; then
			echo >&2 "error: attempting to run rootless dockerd but need 'user.max_user_namespaces' set to a sufficiently large value"
			exit 1
		fi
		exec rootlesskit \
			--net="${DOCKERD_ROOTLESS_ROOTLESSKIT_NET:-vpnkit}" \
			--mtu="${DOCKERD_ROOTLESS_ROOTLESSKIT_MTU:-1500}" \
			--disable-host-loopback \
			--port-driver=builtin \
			--copy-up=/etc \
			--copy-up=/run \
			${DOCKERD_ROOTLESS_ROOTLESSKIT_FLAGS:-} \
			"$@"
	elif [ -x '/usr/local/bin/dind' ]; then
		set -- '/usr/local/bin/dind' "$@"
	fi
fi

exec "$@"
