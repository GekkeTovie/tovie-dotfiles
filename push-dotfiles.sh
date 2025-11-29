#!/usr/bin/env bash
# TovieIT · Mystic Dotfile Uploader
# Pushes ~/dotfiles (including .config/<apps>) to your GitHub repo.

set -euo pipefail

DOTFILES_DIR="$HOME/dotfiles"
VAULT_CONFIG="$DOTFILES_DIR/.config"

# ---------- Colors ----------
if [[ -t 1 ]]; then
  C_RESET="\e[0m"
  C_DIM="\e[2m"
  C_BOLD="\e[1m"
  C_MAGENTA="\e[38;5;135m"
  C_CYAN="\e[38;5;44m"
  C_GREEN="\e[38;5;77m"
  C_YELLOW="\e[38;5;221m"
  C_RED="\e[38;5;203m"
else
  C_RESET=""; C_DIM=""; C_BOLD=""
  C_MAGENTA=""; C_CYAN=""; C_GREEN=""
  C_YELLOW=""; C_RED=""
fi

m_info()  { printf "${C_CYAN}[🔮]${C_RESET} %b\n" "$*"; }
m_ok()    { printf "${C_GREEN}[✨]${C_RESET} %b\n" "$*"; }
m_warn()  { printf "${C_YELLOW}[⚠]${C_RESET} %b\n" "$*"; }
m_err()   { printf "${C_RED}[✖]${C_RESET} %b\n" "$*"; }

# ---------- Banner ----------
clear || true
printf "${C_MAGENTA}${C_BOLD}"
cat << 'EOF'
╔══════════════════════════════════════════════╗
║       TovieIT · Mystic Dotfile Uploader     ║
╚══════════════════════════════════════════════╝
           casting your rice to GitHub
EOF
printf "${C_RESET}\n"

# ---------- Checks ----------
if [[ ! -d "$DOTFILES_DIR" ]]; then
  m_err "No dotfiles vault at $DOTFILES_DIR"
  m_info "Run dotfiles-setup.sh first to create and fill it."
  exit 1
fi

m_info "Dotfiles vault   : ${C_BOLD}$DOTFILES_DIR${C_RESET}"
m_info "Config vault     : ${C_BOLD}$VAULT_CONFIG${C_RESET}"
echo

# Show which configs are tracked in the vault
if [[ -d "$VAULT_CONFIG" ]]; then
  mapfile -t cfg_dirs < <(find "$VAULT_CONFIG" -maxdepth 1 -mindepth 1 -type d -printf "%f\n" | sort)
  if ((${#cfg_dirs[@]} > 0)); then
    printf "${C_BOLD}${C_MAGENTA}Configs in .config vault:${C_RESET}\n\n"
    for d in "${cfg_dirs[@]}"; do
      printf "  ${C_CYAN}%s${C_RESET}  ${C_DIM}(~/.config/%s -> ~/dotfiles/.config/%s)${C_RESET}\n" "$d" "$d" "$d"
    done
    echo
  else
    m_warn "No folders found in $VAULT_CONFIG yet."
  fi
else
  m_warn "Config vault directory $VAULT_CONFIG does not exist (yet)."
fi

cd "$DOTFILES_DIR"

# ---------- Init repo if needed ----------
if [[ ! -d .git ]]; then
  m_info "No git repository detected, conjuring one…"
  if git init -b main 2>/dev/null; then
    m_ok "Initialized git repo with branch 'main'."
  else
    git init
    m_ok "Initialized git repo (using git's default branch)."
  fi
fi

branch="$(git symbolic-ref --short HEAD 2>/dev/null || echo "main")"
m_info "Working on branch: ${C_BOLD}$branch${C_RESET}"

# ---------- Remote setup ----------
if ! git remote get-url origin >/dev/null 2>&1; then
  echo
  m_warn "No 'origin' remote bound yet."
  printf "Paste your GitHub repo URL (SSH or HTTPS), e.g.\n"
  printf "  ${C_DIM}git@github.com:YourUser/your-dotfiles.git${C_RESET}\n"
  printf "  ${C_DIM}https://github.com/YourUser/your-dotfiles.git${C_RESET}\n\n"
  read -rp "$(printf "${C_MAGENTA}> GitHub remote URL${C_RESET} ") " remote_url

  if [[ -z "${remote_url// }" ]]; then
    m_err "No URL provided. Aborting."
    exit 1
  fi

  git remote add origin "$remote_url"
  m_ok "Bound 'origin' to $remote_url"
else
  url="$(git remote get-url origin)"
  m_info "Using existing remote 'origin': ${C_BOLD}$url${C_RESET}"
fi

# ---------- Add & commit ----------
echo
m_info "Staging changes in your dotfile grimoire…"
git add .

if git diff --cached --quiet; then
  m_warn "No changes staged. Nothing new to commit."
else
  default_msg="Update dotfiles $(date '+%Y-%m-%d %H:%M')"
  echo
  printf "${C_BOLD}Commit message${C_RESET} (leave empty for default):\n"
  printf "  ${C_DIM}%s${C_RESET}\n\n" "$default_msg"
  read -rp "$(printf "${C_MAGENTA}> ${C_RESET}") " msg

  msg="${msg:-$default_msg}"

  m_info "Committing with message: ${C_BOLD}$msg${C_RESET}"
  git commit -m "$msg" >/dev/null
  m_ok "Commit created."
fi

# ---------- Push ----------
echo
m_info "Pushing to the cloud realm…"

if git rev-parse --abbrev-ref --symbolic-full-name '@{u}' >/dev/null 2>&1; then
  git push
else
  git push -u origin "$branch"
fi

m_ok "Dotfiles (including .config/<apps>) successfully pushed to GitHub."
echo
printf "${C_DIM}Anyone can now clone your repo and run dotfiles-setup.sh to link ~/.config/<name> -> ~/dotfiles/.config/<name>.${C_RESET}\n"
