function mise_install_python -d 'Wraps python-build for NixOS.'
    nix-shell -p pkg-config openssl libffi zlib bzip2 readline sqlite ncurses libuuid libxcrypt tk xz --run "mise install python@$argv"
end
