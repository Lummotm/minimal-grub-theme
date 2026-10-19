#!/bin/bash

# Root privileges check
if [[ $EUID -ne 0 ]]; then
  tput setaf 1
  printf "\n"
  echo "Root privileges needed. Run the script with sudo." >&2
  printf "\n"
  tput sgr0
  exit 1
fi

# Parse arguments
FONT_SIZE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
  -font)
    if [[ -z "${2:-}" ]]; then
      echo "Error: -font requires a font size." >&2
      echo "Usage: sudo ./Install.sh [-font SIZE]" >&2
      exit 1
    fi
    FONT_SIZE="$2"
    shift 2
    ;;
  -h | --help)
    echo "Usage: sudo ./Install.sh [-font SIZE]"
    echo "  -font SIZE  Set the font size in points."
    exit 0
    ;;
  *)
    echo "Unknown argument: $1" >&2
    echo "Usage: sudo ./Install.sh [-font SIZE]" >&2
    exit 1
    ;;
  esac
done

# Theme name
THEME_NAME=minimal

tput setaf 4
printf "\n"
echo "-----------------------------------" >&2
echo " Installing $THEME_NAME Grub Theme " >&2
echo "-----------------------------------" >&2
printf "\n"
tput sgr0

# GRUB directory check
GRUB_DIR=/boot/grub2
if [[ ! -d "$GRUB_DIR" ]]; then
  GRUB_DIR=/boot/grub
  if [[ ! -d "$GRUB_DIR" ]]; then
    tput setaf 1
    printf "\n"
    echo "Could not find the grub directory" >&2
    printf "\n"
    tput sgr0
    exit 1
  fi
fi

# GRUB-mkconfig command check
GRUB_MKCONFIG=grub2-mkconfig
if ! command -v "$GRUB_MKCONFIG" >/dev/null 2>&1; then
  GRUB_MKCONFIG=grub-mkconfig
  if ! command -v "$GRUB_MKCONFIG" >/dev/null 2>&1; then
    tput setaf 1
    printf "\n"
    echo "Command '$GRUB_MKCONFIG' not found" >&2
    printf "\n"
    tput sgr0
    exit 1
  fi
fi

# Ask for font size if not provided
if [[ -z "$FONT_SIZE" ]]; then
  printf "\n"
  read -r -p "Enter your desired font size (points): " FONT_SIZE
  printf "\n"
fi

# Font size validation
if ! [[ "$FONT_SIZE" =~ ^[1-9][0-9]*$|^0$ ]]; then
  tput setaf 1
  printf "\n"
  echo "Invalid font size. Please enter a positive integer." >&2
  printf "\n"
  tput sgr0
  exit 1
fi

if ((FONT_SIZE < 1)); then
  echo "Font size must be greater than zero." >&2
  exit 1
fi

tput setaf 3
printf "\n"
echo "Selected font size: $FONT_SIZE points" >&2
printf "\n"
tput sgr0

# Generate theme font
grub-mkfont -s "$FONT_SIZE" \
  -o "./$THEME_NAME/custom.pf2" \
  "./$THEME_NAME/original.ttf" || exit 1

# Check GRUB configuration file
GRUB_DEFAULT_FILE="/etc/default/grub"
if [[ ! -f "$GRUB_DEFAULT_FILE" ]]; then
  tput setaf 1
  printf "\n"
  echo "File $GRUB_DEFAULT_FILE does not exist. Exiting." >&2
  printf "\n"
  tput sgr0
  exit 1
fi

# Back up GRUB configuration
cp -a "$GRUB_DEFAULT_FILE" "${GRUB_DEFAULT_FILE}.bak" || exit 1

# Copy theme folder to GRUB directory
mkdir -p "$GRUB_DIR/themes" || exit 1

THEME_DIR="$GRUB_DIR/themes/$THEME_NAME"
rm -rf -- "$THEME_DIR"
cp -rf "./$THEME_NAME" "$GRUB_DIR/themes/" || exit 1

# Replace GRUB_THEME variable
sed -i '/^[[:space:]]*GRUB_THEME[[:space:]]*=/d' "$GRUB_DEFAULT_FILE"
printf 'GRUB_THEME="%s/theme.txt"\n' "$THEME_DIR" >>"$GRUB_DEFAULT_FILE"

# Update GRUB configuration
"$GRUB_MKCONFIG" -o "$GRUB_DIR/grub.cfg" || exit 1

# Final message
tput setaf 2
printf "\n"
echo "-------------------------------------------" >&2
echo " $THEME_NAME Grub Theme Has Been Installed " >&2
echo "-------------------------------------------" >&2
printf "\n"
tput sgr0
