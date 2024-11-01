function kubeconfig_setup
    mkdir -p "$HOME/.kube"
    set -g KUBECONFIG "$(mktemp -d)/config"

    op inject -i $argv[1] -o "$KUBECONFIG"; and ln -s $KUBECONFIG "$HOME/.kube/config"
end

function kubeconfig_cleanup --on-event fish_exit
    if set -q KUBECONFIG
        rm -f "$KUBECONFIG"
        set -e KUBECONFIG
        rm -f "$HOME/.kube/config"
    end
end
