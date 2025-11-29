#!/usr/bin/env bash
# TovieIT · Mystic GitHub SSH Setup
# Generates and configures your SSH key for GitHub access.

set -euo pipefail

EMAIL="merlijndVries@gmail.com"
USER="GekkeTovie"

# Appearance
if [[ -t 1 ]]; then
  C_RESET="\e[0m"
  C_MAGENTA="\e[38;5;135m"
  C_CYAN="\e[38;5;44m"
  C_GREEN="\e[38;5;77m"
  C_YELLOW="\e[38;5;221m"
  C_BOLD="\e[1m"
else
  C_RESET=""; C_MAGENTA=""; C_CYAN=""; C_GREEN=""; C_YELLOW=""; C_BOLD=""
fi

msg() { printf "${C_CYAN}[🔮]${C_RESET} %s\n" "$*"; }
ok()  { printf "${C_GREEN}[✨]${C_RESET} %s\n" "$*"; }
warn(){ printf "${C_YELLOW}[⚠]${C_RESET} %s\n" "$*"; }

clear || true
printf "${C_MAGENTA}${C_BOLD}"
cat << 'EOF'
╔══════════════════════════════════════════════╗
║      TovieIT · Mystic GitHub SSH Setup      ║
╚══════════════════════════════════════════════╝
      forging a key to the GitHub realms…
EOF
printf "${C_RESET}\n"

SSH_DIR="$HOME/.ssh"
KEY="$SSH_DIR/id_ed25519"
PUB="$KEY.pub"

msg "Checking for existing SSH key…"

if [[ -f "$KEY" ]]; then
  ok "An SSH key already exists at $KEY"
else
  msg "No key found — forging a new ed25519 key…"
  mkdir -p "$SSH_DIR"
  ssh-keygen -t ed25519 -C "$EMAIL" -f "$KEY" -N ""
  ok "SSH key generated."
fi

echo
msg "Starting ssh-agent and binding your key…"
eval "$(ssh-agent -s)"
ssh-add "$KEY" >/dev/null
ok "SSH agent is ready."

echo
msg "Your public key (copy this to GitHub → Settings → SSH Keys):"
echo
printf "${C_YELLOW}"
cat "$PUB"
printf "${C_RESET}\n\n"

warn "After adding the key, test it with:"
printf "${C_CYAN}ssh -T git@github.com${C_RESET}\n\n"

msg "Your SSH remote should look like:"
printf "${C_GREEN}git@github.com:$USER/tovie-dotfiles.git${C_RESET}\n\n"

ok "You are now ready to push via SSH!"

