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

# Theme name
THEME_NAME=minimal

tput setaf 4
printf "\n"
echo "-----------------------------------" >&2
echo " Installing $THEME_NAME Grub Theme " >&2
echo "-----------------------------------" >&2
printf "\n"
tput sgr0

# Grub directory check
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

# Grub-mkconfig command check
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

# Font size input validation
printf "\n"
read -r -p "Enter your desired font size (points): " FONT_SIZE
printf "\n"

if ! [[ "$FONT_SIZE" =~ ^[1-9][0-9]*$|^0$ ]]; then
  tput setaf 1
  printf "\n"
  echo "Invalid input. Please enter a valid number in points." >&2
  printf "\n"
  tput sgr0
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
