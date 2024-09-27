function kubeconfig_setup
    set -g KUBECONFIG "$(mktemp -d)/config"
    op inject -i $argv[1] -o "$KUBECONFIG"
end

function kubeconfig_cleanup --on-event fish_exit
    if set -q KUBECONFIG
        rm -rf "$KUBECONFIG"
        set -e KUBECONFIG
    end
end
