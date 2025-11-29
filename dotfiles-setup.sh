#!/usr/bin/env bash
# TovieIT · Mystic Dotfile Weaver (clean layout)
# Moves selected ~/.config folders into ~/dotfiles/.config
# and symlinks them back, ready for GitHub.

set -euo pipefail

DOTFILES_DIR="$HOME/dotfiles"
CONFIG_DIR="$HOME/.config"
VAULT_CONFIG="$DOTFILES_DIR/.config"

# ---------- Colors & Styling ----------
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

m_info()  { printf "${C_CYAN}[🔮]${C_RESET} %s\n" "$*"; }
m_ok()    { printf "${C_GREEN}[✨]${C_RESET} %s\n" "$*"; }
m_warn()  { printf "${C_YELLOW}[⚠]${C_RESET} %s\n" "$*"; }
m_err()   { printf "${C_RED}[✖]${C_RESET} %s\n" "$*"; }

# ---------- Banner ----------
clear || true
printf "${C_MAGENTA}${C_BOLD}"
cat << 'EOF'
╔══════════════════════════════════════════════╗
║        TovieIT · Mystic Dotfile Weaver      ║
╚══════════════════════════════════════════════╝
      weaving configs into the Omarchy ether
EOF
printf "${C_RESET}\n"

# Ensure dotfiles vault + .config exist
if [[ ! -d "$DOTFILES_DIR" ]]; then
  m_info "No dotfiles vault detected, conjuring one at ~/dotfiles…"
  mkdir -p "$DOTFILES_DIR"
  m_ok "Created $DOTFILES_DIR."
fi

mkdir -p "$VAULT_CONFIG"

m_info "Config source     : ${C_BOLD}$CONFIG_DIR${C_RESET}"
m_info "Dotfiles .config  : ${C_BOLD}$VAULT_CONFIG${C_RESET}"
echo

# ---------- Gather names from ~/.config and ~/dotfiles/.config ----------
m_info "Scanning your arcane config tomes…"

declare -A seen

# From ~/.config
if [[ -d "$CONFIG_DIR" ]]; then
  while IFS= read -r d; do
    name="${d##*/}"
    seen["$name"]=1
  done < <(find "$CONFIG_DIR" -maxdepth 1 -mindepth 1 -type d)
fi

# From ~/dotfiles/.config
if [[ -d "$VAULT_CONFIG" ]]; then
  while IFS= read -r d; do
    name="${d##*/}"
    seen["$name"]=1
  done < <(find "$VAULT_CONFIG" -maxdepth 1 -mindepth 1 -type d)
fi

if ((${#seen[@]} == 0)); then
  m_err "No configs found in ~/.config or $VAULT_CONFIG. Nothing to weave."
  exit 1
fi

dirs=()
for k in "${!seen[@]}"; do dirs+=("$k"); done
IFS=$'\n' dirs=($(sort <<<"${dirs[*]}")); unset IFS

echo
printf "${C_BOLD}${C_MAGENTA}Available grimoires:${C_RESET}\n\n"

i=1
for d in "${dirs[@]}"; do
  src_flag=""
  dot_flag=""

  [[ -d "$CONFIG_DIR/$d" ]]       && src_flag="·cfg"
  [[ -d "$VAULT_CONFIG/$d" ]]     && dot_flag="·dot"

  printf "  ${C_MAGENTA}%2d${C_RESET}) ${C_CYAN}%-18s${C_RESET} ${C_DIM}%s%s${C_RESET}\n" \
    "$i" "$d" "$src_flag" "$dot_flag"
  ((i++))
done

echo
printf "${C_DIM}Legend:${C_RESET} ${C_DIM}·cfg${C_RESET}=in ~/.config  ${C_DIM}·dot${C_RESET}=in ~/dotfiles/.config\n\n"

printf "${C_BOLD}How to cast:${C_RESET}\n"
printf "  • Type ${C_YELLOW}names${C_RESET} separated by spaces (e.g. ${C_CYAN}hypr waybar eww${C_RESET})\n"
printf "  • Or type ${C_YELLOW}all${C_RESET} to weave everything listed.\n\n"

read -rp "$(printf "${C_MAGENTA}> Mystic selection${C_RESET} ") " selection

if [[ -z "${selection// }" ]]; then
  m_err "No selection given. Spell fizzled."
  exit 1
fi

if [[ "$selection" == "all" ]]; then
  selected_dirs=("${dirs[@]}")
else
  read -ra selected_dirs <<< "$selection"
fi

echo
m_info "You chose to weave: ${C_BOLD}${selected_dirs[*]}${C_RESET}"
read -rp "$(printf "${C_YELLOW}Proceed (y/N)?${C_RESET} ")" confirm
[[ "$confirm" =~ ^[Yy]$ ]] || { m_warn "Ritual cancelled."; exit 0; }

summary_moved=()
summary_linked=()

for name in "${selected_dirs[@]}"; do
  echo
  printf "${C_BOLD}${C_MAGENTA}◆ Weaving:${C_RESET} ${C_CYAN}%s${C_RESET}\n" "$name"

  src="$CONFIG_DIR/$name"
  vault="$VAULT_CONFIG/$name"

  # If config exists in ~/.config and not yet in vault: move it
  if [[ -d "$src" && ! -d "$vault" ]]; then
    m_info "Moving ${C_CYAN}$src${C_RESET} -> ${C_CYAN}$vault${C_RESET}"
    mkdir -p "$VAULT_CONFIG"
    mv "$src" "$vault"
    m_ok "Config for '$name' bound into dotfiles vault."
    summary_moved+=("$name")
  elif [[ -d "$src" && -d "$vault" ]]; then
    m_warn "'$name' exists in both ~/.config and dotfiles. Leaving vault copy; replacing ~/.config with a link."
    rm -rf "$src"
  elif [[ ! -d "$src" && -d "$vault" ]]; then
    m_info "No live ~/.config/$name, but vault contains it – will just link it."
  else
    m_warn "Skipping '$name' – no config in ~/.config or vault."
    continue
  fi

  # (Re)create symlink in ~/.config
  if [[ -e "$src" || -L "$src" ]]; then
    rm -rf "$src"
  fi

  ln -s "$vault" "$src"
  m_ok "Symlink created: ${C_CYAN}$src -> $vault${C_RESET}"
  summary_linked+=("$name")
done

echo
printf "${C_GREEN}${C_BOLD}✨ Ritual complete!${C_RESET}\n"
m_info "All managed configs now live in: ${C_BOLD}$VAULT_CONFIG${C_RESET}"
m_info "and are symlinked back into:   ${C_BOLD}$CONFIG_DIR${C_RESET}"
echo

if ((${#summary_moved[@]} > 0)); then
  printf "${C_CYAN}Moved into vault:${C_RESET} %s\n" "${summary_moved[*]}"
fi
if ((${#summary_linked[@]} > 0)); then
  printf "${C_CYAN}Linked configs  :${C_RESET} %s\n" "${summary_linked[*]}"
fi

echo
printf "${C_DIM}On GitHub you'll now see: .config/<name> instead of <name>/.config/<name>.${C_RESET}\n"
