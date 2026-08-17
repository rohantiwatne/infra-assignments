#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECK_ONLY=0

# Minimum required Go version.
MIN_GO_MAJOR=1
MIN_GO_MINOR=25

# Current Go version to install when Go is missing/outdated.
GO_VERSION="1.26.5"

info(){ printf '\033[1;34m[INFO]\033[0m %s\n' "$*"; }
ok(){ printf '\033[1;32m[ OK ]\033[0m %s\n' "$*"; }
warn(){ printf '\033[1;33m[WARN]\033[0m %s\n' "$*" >&2; }
fail(){ printf '\033[1;31m[FAIL]\033[0m %s\n' "$*" >&2; }
have(){ command -v "$1" >/dev/null 2>&1; }

for arg in "$@"; do
  case "$arg" in
    --check-only)
      CHECK_ONLY=1
      ;;

    -h|--help)
      cat <<'HELP'
Usage: ./install.sh [--check-only]

Installs/checks:
  Git, curl, jq, make
  Go 1.25+
  Docker / Docker Desktop availability
  Terraform
  kubectl
  Minikube

Windows:
  Run from WSL 2 (recommended) or Git Bash.

Examples:
  ./install.sh
  ./install.sh --check-only
HELP
      exit 0
      ;;

    *)
      fail "Unknown option: $arg"
      exit 2
      ;;
  esac
done

OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"
IS_WSL=0

if [[ -r /proc/version ]] && grep -qi microsoft /proc/version; then
  IS_WSL=1
fi

if [[ "$OS" == "darwin" ]]; then
  PLATFORM="macos"

elif [[ "$OS" == "linux" && "$IS_WSL" == "1" ]]; then
  PLATFORM="windows-wsl"

elif [[ "$OS" == "linux" ]]; then
  PLATFORM="linux"

elif [[ "$OS" == msys* || "$OS" == mingw* || "$OS" == cygwin* ]]; then
  PLATFORM="windows-git-bash"

else
  fail "Unsupported operating system: $OS"
  exit 1
fi

info "Platform: $PLATFORM / architecture: $ARCH"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

sudo_cmd(){
  if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    "$@"
  else
    if ! have sudo; then
      fail "sudo is required but was not found."
      return 1
    fi
    sudo "$@"
  fi
}

brew_install(){
  if ! have brew; then
    fail "Homebrew is not installed."
    return 1
  fi

  brew install "$@"
}

apt_install(){
  sudo_cmd apt-get update
  sudo_cmd apt-get install -y "$@"
}

dnf_install(){
  if have dnf; then
    sudo_cmd dnf install -y "$@"
  elif have yum; then
    sudo_cmd yum install -y "$@"
  else
    return 1
  fi
}

# Convert uname architecture to Go architecture.
go_arch(){
  case "$ARCH" in
    x86_64|amd64)
      echo "amd64"
      ;;
    aarch64|arm64)
      echo "arm64"
      ;;
    *)
      fail "Unsupported architecture for Go: $ARCH"
      return 1
      ;;
  esac
}

# ---------------------------------------------------------------------------
# Go version checking
# ---------------------------------------------------------------------------

get_go_version(){
  if ! have go; then
    return 1
  fi

  go version | sed -E 's/.*go([0-9]+)\.([0-9]+)(\.[0-9]+)?.*/\1 \2 \3/'
}

go_is_new_enough(){
  local version
  local major
  local minor

  version="$(get_go_version)" || return 1

  major="$(awk '{print $1}' <<< "$version")"
  minor="$(awk '{print $2}' <<< "$version")"

  if [[ "$major" -gt "$MIN_GO_MAJOR" ]]; then
    return 0
  fi

  if [[ "$major" -eq "$MIN_GO_MAJOR" && "$minor" -ge "$MIN_GO_MINOR" ]]; then
    return 0
  fi

  return 1
}

# ---------------------------------------------------------------------------
# Homebrew
# ---------------------------------------------------------------------------

install_homebrew(){
  [[ "$PLATFORM" == "macos" ]] || return 0

  if have brew; then
    return 0
  fi

  if [[ "$CHECK_ONLY" == "1" ]]; then
    fail "Homebrew is not installed."
    return 1
  fi

  info "Installing Homebrew..."

  /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi

  if [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi

  if ! have brew; then
    fail "Homebrew installation completed but brew is not available."
    fail "Restart your terminal and rerun ./install.sh."
    return 1
  fi
}

# ---------------------------------------------------------------------------
# Basic dependencies
# ---------------------------------------------------------------------------

install_basic(){
  case "$PLATFORM" in

    macos)
      have git || brew_install git
      have curl || brew_install curl
      have jq || brew_install jq
      have make || brew_install make
      ;;

    linux|windows-wsl)
      local pkgs=()

      have git || pkgs+=(git)
      have curl || pkgs+=(curl)
      have jq || pkgs+=(jq)
      have make || pkgs+=(make)

      if ((${#pkgs[@]})); then
        if have apt-get; then
          apt_install "${pkgs[@]}"
        elif have dnf || have yum; then
          dnf_install "${pkgs[@]}"
        else
          warn "Install manually: ${pkgs[*]}"
        fi
      fi
      ;;

    windows-git-bash)
      warn "Git Bash detected."
      warn "Git and curl normally come from Git for Windows."

      # jq and make are not guaranteed by Git for Windows.
      if ! have jq; then
        warn "jq is missing. Install jq for Windows or use WSL 2."
      fi

      if ! have make; then
        warn "make is missing. Install make or use WSL 2."
      fi
      ;;

  esac
}

# ---------------------------------------------------------------------------
# Go installation
# ---------------------------------------------------------------------------

install_go(){

  # Already installed and acceptable.
  if have go && go_is_new_enough; then
    ok "Go 1.25+ detected: $(go version)"
    return 0
  fi

  # Existing Go is too old.
  if have go; then
    warn "Installed Go is older than 1.25: $(go version)"
  else
    warn "Go is not installed."
  fi

  if [[ "$CHECK_ONLY" == "1" ]]; then
    fail "Go 1.25+ is required."
    return 1
  fi

  case "$PLATFORM" in

    # -----------------------------------------------------------------------
    # macOS
    # -----------------------------------------------------------------------
    macos)
      info "Installing Go ${GO_VERSION} on macOS..."

      # Homebrew's Go package tracks a supported Go release.
      brew_install go

      # Homebrew may install into its own prefix.
      if have brew; then
        export PATH="$(brew --prefix)/bin:$PATH"
      fi
      ;;

    # -----------------------------------------------------------------------
    # Linux / WSL 2
    # -----------------------------------------------------------------------
    linux|windows-wsl)
      local ga
      ga="$(go_arch)"

      local tmp="/tmp/go${GO_VERSION}.linux-${ga}.tar.gz"
      local url="https://go.dev/dl/go${GO_VERSION}.linux-${ga}.tar.gz"

      info "Installing Go ${GO_VERSION} for Linux (${ga})..."
      info "Downloading: ${url}"

      curl -fL "$url" -o "$tmp"

      sudo_cmd rm -rf /usr/local/go
      sudo_cmd tar -C /usr/local -xzf "$tmp"

      rm -f "$tmp"

      export PATH="/usr/local/go/bin:$PATH"

      # Make Go available for future shells.
      local shell_profile="$HOME/.profile"

      if [[ -d "/usr/local/go/bin" ]]; then
        if ! grep -q '/usr/local/go/bin' "$shell_profile" 2>/dev/null; then
          cat >> "$shell_profile" <<'PROFILE'

# Go
export PATH="/usr/local/go/bin:$PATH"
PROFILE
        fi
      fi
      ;;

    # -----------------------------------------------------------------------
    # Windows Git Bash
    # -----------------------------------------------------------------------
    windows-git-bash)
      info "Installing Go ${GO_VERSION} on Windows..."

      # Prefer winget.exe because Git Bash can invoke Windows executables.
      if have winget.exe; then

        info "Installing Go using Windows winget..."

        winget.exe install \
          --id GoLang.Go \
          -e \
          --accept-source-agreements \
          --accept-package-agreements

      else
        fail "winget.exe is not available."
        fail "Install Go 1.25+ from https://go.dev/dl/ and rerun ./install.sh."
        return 1
      fi

      # ---------------------------------------------------------------------
      # Refresh PATH.
      #
      # Go's standard Windows installation directory is:
      #
      #   C:\Program Files\Go\bin
      #
      # Git Bash represents this as:
      #
      #   /c/Program Files/Go/bin
      # ---------------------------------------------------------------------

      local windows_go="/c/Program Files/Go/bin"

      if [[ -d "$windows_go" ]]; then
        export PATH="$windows_go:$PATH"
      fi

      # Some installations may expose go.exe through the Windows PATH.
      # Import Windows PATH if necessary.
      if ! have go && have powershell.exe; then
        local windows_path

        windows_path="$(
          powershell.exe -NoProfile -Command \
            '[Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [Environment]::GetEnvironmentVariable("Path","User")' \
          2>/dev/null \
          | tr -d '\r'
        )" || true

        if [[ -n "${windows_path:-}" ]]; then
          local path_entry
          local bash_entry

          while IFS=';' read -r path_entry; do
            [[ -z "$path_entry" ]] && continue

            bash_entry="$(
              cygpath -u "$path_entry" 2>/dev/null || true
            )"

            if [[ -n "$bash_entry" && -d "$bash_entry" ]]; then
              export PATH="$bash_entry:$PATH"
            fi
          done <<< "$windows_path"
        fi
      fi

      # Final direct check.
      if have go; then
        ok "Go installed: $(go version)"
      else
        warn "Go was installed by Windows, but this Git Bash session cannot see it yet."
        warn "Close Git Bash, open a new Git Bash window, and rerun ./install.sh."
        return 1
      fi
      ;;

  esac

  # Final validation.
  if ! have go; then
    fail "Go installation failed: 'go' command is not available."
    return 1
  fi

  if ! go_is_new_enough; then
    fail "Go installation completed, but Go 1.25+ was not detected."
    fail "Detected: $(go version)"
    return 1
  fi

  ok "Go ready: $(go version)"
}

# ---------------------------------------------------------------------------
# Docker
# ---------------------------------------------------------------------------

ensure_docker(){

  if have docker && docker info >/dev/null 2>&1; then
    ok "Docker is installed and running."
    return 0
  fi

  if have docker; then
    warn "Docker CLI is installed but the Docker daemon is not reachable."
  else
    warn "Docker is not installed."
  fi

  if [[ "$CHECK_ONLY" == "1" ]]; then
    fail "Docker is missing or the daemon is not running."
    return 1
  fi

  case "$PLATFORM" in

    macos|windows-wsl|windows-git-bash)
      warn "Install and start Docker Desktop, then rerun ./install.sh."
      warn "https://www.docker.com/products/docker-desktop/"
      ;;

    linux)
      if have apt-get; then
        apt_install docker.io docker-compose-v2 || return 1

      elif have dnf || have yum; then
        dnf_install docker docker-compose-plugin || return 1

      else
        fail "No supported Linux package manager found for Docker."
        return 1
      fi

      sudo_cmd systemctl enable --now docker 2>/dev/null || true
      ;;

  esac
}

# ---------------------------------------------------------------------------
# Terraform
# ---------------------------------------------------------------------------

ensure_terraform(){

  if have terraform; then
    ok "Terraform detected: $(terraform version | head -n1)"
    return 0
  fi

  if [[ "$CHECK_ONLY" == "1" ]]; then
    fail "Terraform is required."
    return 1
  fi

  case "$PLATFORM" in

    macos)
      info "Installing Terraform using Homebrew..."

      brew tap hashicorp/tap
      brew_install hashicorp/tap/terraform
      ;;

    linux|windows-wsl)
      if have apt-get; then

        info "Installing Terraform..."

        apt_install gnupg

        curl -fsSL \
          https://apt.releases.hashicorp.com/gpg \
          | sudo_cmd gpg --dearmor \
              -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

        . /etc/os-release

        if [[ -z "${VERSION_CODENAME:-}" ]]; then
          fail "Could not determine Linux VERSION_CODENAME."
          return 1
        fi

        echo \
          "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com ${VERSION_CODENAME} main" \
          | sudo_cmd tee /etc/apt/sources.list.d/hashicorp.list >/dev/null

        sudo_cmd apt-get update
        sudo_cmd apt-get install -y terraform

      else
        fail "Install Terraform from https://developer.hashicorp.com/terraform/install"
        return 1
      fi
      ;;

    windows-git-bash)
      if have winget.exe; then
        info "Installing Terraform using Windows winget..."

        winget.exe install \
          --id Hashicorp.Terraform \
          -e \
          --accept-source-agreements \
          --accept-package-agreements

        # Refresh Windows PATH.
        if have powershell.exe; then
          local terraform_path

          terraform_path="$(
            powershell.exe -NoProfile -Command \
              '[Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [Environment]::GetEnvironmentVariable("Path","User")' \
            2>/dev/null \
            | tr -d '\r'
          )" || true

          if [[ -n "${terraform_path:-}" ]]; then
            local entry
            local bash_entry

            while IFS=';' read -r entry; do
              [[ -z "$entry" ]] && continue

              bash_entry="$(
                cygpath -u "$entry" 2>/dev/null || true
              )"

              if [[ -n "$bash_entry" && -d "$bash_entry" ]]; then
                export PATH="$bash_entry:$PATH"
              fi
            done <<< "$terraform_path"
          fi
        fi

        if have terraform; then
          ok "Terraform installed: $(terraform version | head -n1)"
        else
          warn "Terraform was installed but is not visible in this Git Bash session."
          warn "Restart Git Bash and rerun ./install.sh."
          return 1
        fi

      else
        fail "winget.exe is not available."
        fail "Install Terraform from https://developer.hashicorp.com/terraform/install"
        return 1
      fi
      ;;

  esac
}

# ---------------------------------------------------------------------------
# Kubernetes
# ---------------------------------------------------------------------------

ensure_k8s(){

  if have kubectl && have minikube; then
    ok "kubectl and Minikube detected."
    return 0
  fi

  if [[ "$CHECK_ONLY" == "1" ]]; then
    fail "kubectl and Minikube are required."
    return 1
  fi

  case "$PLATFORM" in

    macos)
      have kubectl || brew_install kubectl
      have minikube || brew_install minikube
      ;;

    linux|windows-wsl)

      if ! have kubectl; then
        local ka
        ka="$ARCH"

        [[ "$ka" == "x86_64" ]] && ka="amd64"
        [[ "$ka" == "aarch64" ]] && ka="arm64"

        local version
        version="$(curl -L -s https://dl.k8s.io/release/stable.txt)"

        curl -fL \
          "https://dl.k8s.io/release/${version}/bin/linux/${ka}/kubectl" \
          -o /tmp/kubectl

        chmod +x /tmp/kubectl
        sudo_cmd mv /tmp/kubectl /usr/local/bin/kubectl
      fi

      if ! have minikube; then
        local ma
        ma="$ARCH"

        [[ "$ma" == "x86_64" ]] && ma="amd64"
        [[ "$ma" == "aarch64" ]] && ma="arm64"

        curl -fL \
          "https://storage.googleapis.com/minikube/releases/latest/minikube-linux-${ma}" \
          -o /tmp/minikube

        chmod +x /tmp/minikube
        sudo_cmd mv /tmp/minikube /usr/local/bin/minikube
      fi
      ;;

    windows-git-bash)

      if have winget.exe; then

        if ! have kubectl; then
          info "Installing kubectl using winget..."

          winget.exe install \
            --id Kubernetes.kubectl \
            -e \
            --accept-source-agreements \
            --accept-package-agreements
        fi

        if ! have minikube; then
          info "Installing Minikube using winget..."

          winget.exe install \
            --id Kubernetes.minikube \
            -e \
            --accept-source-agreements \
            --accept-package-agreements
        fi

        warn "kubectl/Minikube may require a new Git Bash session to appear in PATH."

      else
        warn "winget.exe is not available."
        warn "Install on Windows:"
        warn "  winget install Kubernetes.kubectl"
        warn "  winget install Kubernetes.minikube"
        return 1
      fi
      ;;

  esac
}

# ---------------------------------------------------------------------------
# Project preparation
# ---------------------------------------------------------------------------

prepare_project(){

  local tfvars="$PROJECT_ROOT/infra/terraform/terraform.tfvars"
  local example="$PROJECT_ROOT/infra/terraform/terraform.tfvars.example"

  if [[ "$CHECK_ONLY" == "0" && -f "$example" && ! -f "$tfvars" ]]; then
    cp "$example" "$tfvars"
    chmod 600 "$tfvars"

    warn "Created local $tfvars from the example."
    warn "The file should be gitignored."
  fi
}

# ---------------------------------------------------------------------------
# Final verification
# ---------------------------------------------------------------------------

verify(){

  local failed=0

  for cmd in git curl make go docker terraform kubectl minikube; do
    if have "$cmd"; then
      ok "$cmd available"
    else
      fail "$cmd missing"
      failed=1
    fi
  done

  # Verify Go version.
  if have go; then
    if go_is_new_enough; then
      ok "Go version is supported: $(go version)"
    else
      fail "Go 1.25+ is required: $(go version)"
      failed=1
    fi
  fi

  # Verify Docker daemon.
  if have docker; then
    if docker info >/dev/null 2>&1; then
      ok "Docker daemon is reachable."
    else
      fail "Docker daemon is not reachable."
      failed=1
    fi
  fi

  return "$failed"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

info "Starting environment setup..."
info "Project root: $PROJECT_ROOT"
info "Platform: $PLATFORM / architecture: $ARCH"

install_homebrew
install_basic
install_go
ensure_docker
ensure_terraform
ensure_k8s
prepare_project

info "Final prerequisite check"

if ! verify; then
  fail "One or more prerequisites are missing or unavailable."
  exit 1
fi

ok "All prerequisites are available."

cat <<EOF

Environment is ready.

Next steps:

  minikube start --driver=docker

  cd "$PROJECT_ROOT/app" && go mod tidy && go test ./... && cd "$PROJECT_ROOT"

  make all

  make validate

On Windows:
  WSL 2 + Docker Desktop WSL integration is recommended.

For Git Bash:
  Docker Desktop must be running.
  If Go/Terraform/kubectl/Minikube were installed by winget,
  restart Git Bash if the commands are not immediately available.

EOF