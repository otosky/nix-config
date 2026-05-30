ssh_dir := "/mnt/persist/etc/ssh"
usql_compose := "dev/usql-postgres/compose.yaml"
usql_env := 'USQL_CONFIG_TEMPLATE="$PWD/dev/usql-postgres/config.yaml.tpl" OP_BIN="$PWD/dev/usql-postgres/op-inject-copy"'

# list all recipes
default:
    just --list

# validate nix flake
lint:
    nix fmt -- --check .
    nix flake check

setup:
    curl -sSL https://keybase.io/otosky/pgp_keys.asc | gpg --import

init-keys:
    sudo mkdir -p {{ ssh_dir }}
    cp /etc/ssh/ssh_host_ed25519* {{ ssh_dir }}
    nix-shell --run "sudo ssh-to-age -private-key -i {{ ssh_dir }}/ssh_host_ed25519_key -o {{ ssh_dir }}/age_key.txt"
    nix-shell --run "sudo ssh-to-age -i {{ ssh_dir }}/ssh_host_ed25519_key.pub -o {{ ssh_dir }}/pub.txt"

# build custom installer iso
build-iso:
    cd installer && nix build .#nixosConfigurations.customIso.config.system.build.isoImage

# set up drives & partitions
disko-init host:
    sudo disko -m disko --flake .#{{host}}

# mount initialized drives to filesystem
disko-mount host:
    sudo disko -m mount --flake .#{{host}}

# init nix install on a mounted filesystem
install host:
    sudo nixos-install --root /mnt --flake .#{{host}}

# rebuild flake
rebuild host:
    sudo nixos-rebuild switch --flake .#{{host}}

# update a single flake input in flake.lock
update-input input:
    nix flake update {{input}}

# start a disposable local Postgres for usqlp/neovim testing
usql-postgres-up:
    docker compose -f {{ usql_compose }} up -d
    for i in $(seq 1 30); do docker compose -f {{ usql_compose }} exec -T postgres pg_isready -U usql -d usql_test && exit 0; sleep 1; done; exit 1

# test the disposable local Postgres through usqlp
usql-postgres-test:
    just usql-postgres-up
    {{ usql_env }} usqlp --refresh
    {{ usql_env }} usqlp local_postgres -c 'select count(*) as widget_count from widgets;'

# stop and remove the disposable local Postgres
usql-postgres-down:
    docker compose -f {{ usql_compose }} down -v
