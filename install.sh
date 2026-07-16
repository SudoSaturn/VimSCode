#!/usr/bin/env bash
set -euo pipefail

NVIM_VERSION_REQUIRED="0.12.0"
REPO_URL="https://github.com/SudoSaturn/nvim-vscode"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
BACKUP_DIR="${CONFIG_DIR}.backup.$(date +%s)"

check_nvim() {
    if ! command -v nvim &>/dev/null; then
        echo "Error: Neovim not found. Please install Neovim ${NVIM_VERSION_REQUIRED}+ first."
        exit 1
    fi
    local version=$(nvim --version | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
    if ! printf '%s\n%s\n' "${NVIM_VERSION_REQUIRED}" "${version}" | sort -V | head -1 | grep -q "${NVIM_VERSION_REQUIRED}"; then
        echo "Error: Neovim ${NVIM_VERSION_REQUIRED}+ required (found ${version})."
        exit 1
    fi
}

check_deps() {
    local missing=()
    for cmd in git curl; do
        command -v "$cmd" &>/dev/null || missing+=("$cmd")
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "Error: Missing dependencies: ${missing[*]}"
        exit 1
    fi
}

main() {
    check_deps
    check_nvim

    if [[ -d "${CONFIG_DIR}" && ! -L "${CONFIG_DIR}" ]]; then
        echo "Backing up existing config to ${BACKUP_DIR}"
        mv "${CONFIG_DIR}" "${BACKUP_DIR}"
    fi

    echo "Cloning NVICode configuration from ${REPO_URL}..."
    git clone --depth 1 "${REPO_URL}" "${CONFIG_DIR}"

    echo "Bootstrapping plugins via vim.pack..."
    nvim --headless "+lua require('config.plugins').setup()" "+qall" 2>&1 | tail -20

    echo "Installing Tree-sitter parsers..."
    nvim --headless "+TSInstallSync bash html javascript json lua markdown python typescript yaml" "+qall" 2>&1 | tail -10

    echo "Installing LSP servers via Mason..."
    nvim --headless "+MasonInstall lua_ls jsonls basedpyright vtsls" "+qall" 2>&1 | tail -10

    echo "Installing formatters via Mason..."
    nvim --headless "+MasonInstall prettierd prettier stylua ruff_format shfmt" "+qall" 2>&1 | tail -10

    echo ""
    echo "Installation complete! Start Neovim with: nvim"
    echo "Use Ctrl+Shift+P for command palette, Ctrl+B for sidebar, :Store for extensions"
}

main "$@"