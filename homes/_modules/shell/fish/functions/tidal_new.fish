function tidal_new
    if test (count $argv) -eq 0
        echo "Usage: tidal_new <project-name>"
        return 1
    end
    nix flake new --template github:mitchmindtree/tidalcycles.nix#templates.default $argv[1]
end
