#!/usr/bin/env bash
# TovieIT · Mystic Dotfile Weaver
# Moves selected ~/.config folders into ~/dotfiles/.config/<name>
# and symlinks them back. Also migrates old <name>/.config/<name> layouts.

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

m_info()  { printf "${C_CYAN}[🔮]${C_RESET} %b\n" "$*"; }
m_ok()    { printf "${C_GREEN}[✨]${C_RESET} %b\n" "$*"; }
m_warn()  { printf "${C_YELLOW}[⚠]${C_RESET} %b\n" "$*"; }
m_err()   { printf "${C_RED}[✖]${C_RESET} %b\n" "$*"; }

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

# ---------- Ensure dotfiles vault exists ----------
if [[ ! -d "$DOTFILES_DIR" ]]; then
  m_info "No dotfiles vault detected, conjuring one at ~/dotfiles…"
  mkdir -p "$DOTFILES_DIR"
  m_ok "Created $DOTFILES_DIR."
fi

mkdir -p "$VAULT_CONFIG"

m_info "Config source     : ${C_BOLD}$CONFIG_DIR${C_RESET}"
m_info "Dotfiles .config  : ${C_BOLD}$VAULT_CONFIG${C_RESET}"
echo

# ---------- Legacy migration helper ----------
migrate_legacy_layout() {
  local name="$1"
  local vault_dir="$VAULT_CONFIG/$name"
  local nested="$vault_dir/.config/$name"

  # Old layout: ~/dotfiles/.config/<name>/.config/<name>
  if [[ -d "$nested" ]]; then
    m_warn "Found legacy layout for '$name' at $nested – migrating to flat layout…"
    mkdir -p "$vault_dir"

    shopt -s dotglob
    mv "$nested"/* "$vault_dir"/
    shopt -u dotglob

    rmdir "$nested" 2>/dev/null || true
    rmdir "$vault_dir/.config" 2>/dev/null || true

    m_ok "Migrated '$name' to flat layout: $vault_dir"
  fi
}

# ---------- Gather config names ----------
m_info "Scanning your arcane config tomes…"

declare -A seen

# From ~/.config
if [[ -d "$CONFIG_DIR" ]]; then
  while IFS= read -r path; do
    name="${path##*/}"
    [[ "$name" == .* ]] && continue   # skip dot dirs like .git
    seen["$name"]=1
  done < <(find "$CONFIG_DIR" -maxdepth 1 -mindepth 1 -type d)
fi

# From ~/dotfiles/.config
if [[ -d "$VAULT_CONFIG" ]]; then
  while IFS= read -r path; do
    name="${path##*/}"
    [[ "$name" == .* ]] && continue
    seen["$name"]=1
  done < <(find "$VAULT_CONFIG" -maxdepth 1 -mindepth 1 -type d)
fi

if ((${#seen[@]} == 0)); then
  m_err "No configs found in ~/.config or $VAULT_CONFIG. Nothing to weave."
  exit 1
fi

dirs=()
for k in "${!seen[@]}"; do dirs+=("$k"); done
IFS=$'\n' dirs=($(printf '%s\n' "${dirs[@]}" | sort)); unset IFS

echo
printf "${C_BOLD}${C_MAGENTA}Available grimoires:${C_RESET}\n\n"

i=1
for d in "${dirs[@]}"; do
  src_flag=""
  dot_flag=""

  [[ -d "$CONFIG_DIR/$d" ]]   && src_flag="·cfg"
  [[ -d "$VAULT_CONFIG/$d" ]] && dot_flag="·dot"

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

# ---------- Main loop ----------
for name in "${selected_dirs[@]}"; do
  echo
  printf "${C_BOLD}${C_MAGENTA}◆ Weaving:${C_RESET} ${C_CYAN}%s${C_RESET}\n" "$name"

  src="$CONFIG_DIR/$name"
  vault="$VAULT_CONFIG/$name"

  migrate_legacy_layout "$name"

  if [[ -d "$src" && ! -L "$src" && ! -d "$vault" ]]; then
    m_info "Moving ${C_CYAN}$src${C_RESET} -> ${C_CYAN}$vault${C_RESET}"
    mkdir -p "$VAULT_CONFIG"
    mv "$src" "$vault"
    m_ok "Config for '$name' bound into dotfiles vault."
    summary_moved+=("$name")

  elif [[ -d "$src" && ! -L "$src" && -d "$vault" ]]; then
    m_warn "'$name' exists in both ~/.config and vault. Keeping vault copy and replacing ~/.config with a symlink."
    rm -rf "$src"

  elif [[ ! -d "$src" && -d "$vault" ]]; then
    m_info "No live ~/.config/$name, but vault contains it – will just link it."

  elif [[ -L "$src" ]]; then
    m_info "~/.config/$name is already a symlink. Recreating it to be sure."
    rm -f "$src"

  else
    m_warn "Skipping '$name' – no config in ~/.config or vault."
    continue
  fi

  if [[ -d "$vault" ]]; then
    [[ -e "$src" || -L "$src" ]] && rm -rf "$src"
    ln -s "$vault" "$src"
    m_ok "Symlink created: ${C_CYAN}$src -> $vault${C_RESET}"
    summary_linked+=("$name")
  else
    m_warn "Vault path $vault does not exist for '$name'; nothing to link."
  fi
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
printf "${C_DIM}Layout is now flat: ~/dotfiles/.config/<name>/… and ~/.config/<name> -> that folder.${C_RESET}\n"
