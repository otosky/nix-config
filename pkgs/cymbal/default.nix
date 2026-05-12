{
  lib,
  buildGoModule,
  fetchFromGitHub,
}: let
  version = "0.13.1";
  commit = "29e6fb8bfbb9e95355634dec5574cd9c7ba159bd";
in
  buildGoModule {
    pname = "cymbal";
    inherit version;

    src = fetchFromGitHub {
      owner = "1broseidon";
      repo = "cymbal";
      tag = "v${version}";
      hash = "sha256-ltooj0fH3LmtwDz2OpI33xzBHFJJb1r2bqHKsOFKzWM=";
    };

    vendorHash = "sha256-b05Mz06EGHKnsK8d35jRT+GxjNsSeKGEA3G//twntk4=";
    proxyVendor = true;

    env.CGO_ENABLED = "1";
    env.CGO_CFLAGS = "-DSQLITE_ENABLE_FTS5";

    ldflags = [
      "-s"
      "-w"
      "-X github.com/1broseidon/cymbal/cmd.version=v${version}"
      "-X github.com/1broseidon/cymbal/cmd.commit=${commit}"
    ];

    # Nix-managed packages should not phone home or suggest non-Nix update
    # commands. Stubbing updatecheck also removes the only reachable net/http
    # path from the binary while this flake's pinned nixpkgs Go is 1.26.2.
    postPatch = ''
      cat > internal/updatecheck/updatecheck.go <<'EOF'
      package updatecheck

      import (
      	"context"
      	"strings"
      	"time"
      )

      type InstallType string

      const (
      	InstallUnknown    InstallType = "unknown"
      	InstallHomebrew   InstallType = "homebrew"
      	InstallPowerShell InstallType = "powershell"
      	InstallDocker     InstallType = "docker"
      	InstallGo         InstallType = "go"
      	InstallManual     InstallType = "manual"
      )

      type Options struct {
      	CurrentVersion string
      	AllowNetwork   bool
      	Timeout        time.Duration
      }

      type Status struct {
      	CheckedAt     time.Time   `json:"checked_at,omitempty"`
      	CacheStale    bool        `json:"cache_stale"`
      	Available     bool        `json:"available"`
      	LatestVersion string      `json:"latest_version,omitempty"`
      	InstallType   InstallType `json:"install_type,omitempty"`
      	Command       string      `json:"command,omitempty"`
      	ReleaseURL    string      `json:"release_url,omitempty"`
      	Source        string      `json:"source,omitempty"`
      }

      func Disabled() bool { return true }

      func GetStatus(ctx context.Context, opts Options) (Status, error) {
      	_ = ctx
      	_ = opts
      	return Status{InstallType: InstallUnknown, Source: "disabled"}, nil
      }

      func ShouldNotify(status Status) bool {
      	_ = status
      	return false
      }

      func MarkNotified(status Status) error {
      	_ = status
      	return nil
      }

      func FormatNotice(status Status) string {
      	_ = status
      	return ""
      }

      func AugmentReminder(base string, status Status) string {
      	_ = status
      	return strings.TrimRight(base, "\n")
      }
      EOF
    '';

    doCheck = false;

    meta = {
      description = "Fast, language-agnostic code indexer and symbol navigator powered by tree-sitter";
      homepage = "https://github.com/1broseidon/cymbal";
      changelog = "https://github.com/1broseidon/cymbal/blob/v${version}/CHANGELOG.md";
      license = lib.licenses.mit;
      mainProgram = "cymbal";
      platforms = lib.platforms.unix;
    };
  }
