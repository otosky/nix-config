#!/usr/bin/env bash

nix --experimental-features "nix-command flakes" \
	run github:nix-community/disko -- \
	-m disko \
	--flake github:otosky/nix-config.#ot-desktop
