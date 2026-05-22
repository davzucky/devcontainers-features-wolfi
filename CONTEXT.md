# DevContainer Features for Wolfi

This context describes the product language for Wolfi-compatible DevContainer features in this repository.

## Language

**Feature**:
A reusable DevContainer capability that installs tooling and optionally prepares user-specific files inside a container.
_Avoid_: Plugin, package

**Host staging directory**:
A temporary host directory used to make selected host files available to a container during startup.
_Avoid_: Shared folder, temp copy

**Container running user**:
The user account inside the container that should receive user-specific configuration files.
_Avoid_: Remote user, target user, container user

**Pi agent directory**:
The user-level Pi configuration directory at `~/.pi/agent` containing Pi settings, credentials, customizations, and installed Pi packages. In this repository's Pi feature discussions, `.pi/agent` means `~/.pi/agent` unless explicitly described as project-local.
_Avoid_: Pi config folder, Pi home

## Example dialogue

Developer: Should the Pi feature copy the whole Pi agent directory into the container running user's home?

Domain expert: No. The host staging directory may contain many Pi files, but the feature should move only the selected categories into the container running user's Pi agent directory.
