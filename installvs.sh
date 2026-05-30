#!/bin/bash

INSTALL_DIR="/opt/vintagestory"
DESKTOP_FILE="/usr/share/applications/vintagestory.desktop"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

get_version() {
    if [ -f "$INSTALL_DIR/.version" ]; then
        cat "$INSTALL_DIR/.version"
    else
        echo "Unknown"
    fi
}

is_installed() {
    [ -f "$INSTALL_DIR/Vintagestory" ]
}

install_game() {

    echo
    read -rp "Archive path: " ARCHIVE

    if [ ! -f "$ARCHIVE" ]; then
        echo -e "${RED}Archive not found.${NC}"
        return
    fi

    VERSION=$(basename "$ARCHIVE" | grep -oP '\d+\.\d+\.\d+' | head -n1)

    echo
    echo -e "${BLUE}Installing dependencies...${NC}"

    sudo pacman -Sy --needed dotnet-runtime openal

    TMP_DIR=$(mktemp -d)

    echo -e "${BLUE}Extracting archive...${NC}"

    if ! tar -xf "$ARCHIVE" -C "$TMP_DIR"; then
        echo -e "${RED}Failed to extract archive.${NC}"
        rm -rf "$TMP_DIR"
        return
    fi

    EXTRACTED_DIR=$(find "$TMP_DIR" -mindepth 1 -maxdepth 1 -type d | head -n1)

    if [ -z "$EXTRACTED_DIR" ]; then
        echo -e "${RED}Invalid archive structure.${NC}"
        rm -rf "$TMP_DIR"
        return
    fi

    echo -e "${BLUE}Installing files...${NC}"

    sudo mkdir -p "$INSTALL_DIR"
    sudo rm -rf "$INSTALL_DIR"/*
    sudo cp -a "$EXTRACTED_DIR"/. "$INSTALL_DIR"/

    if [ -n "$VERSION" ]; then
        echo "$VERSION" | sudo tee "$INSTALL_DIR/.version" >/dev/null
    fi

    sudo chmod +x "$INSTALL_DIR/run.sh" 2>/dev/null
    sudo chmod +x "$INSTALL_DIR/Vintagestory" 2>/dev/null

    echo -e "${BLUE}Creating desktop entry...${NC}"

    sudo tee "$DESKTOP_FILE" >/dev/null <<EOF
[Desktop Entry]
Name=Vintage Story
Comment=Vintage Story
Exec=/opt/vintagestory/run.sh
Icon=/opt/vintagestory/assets/gameicon.png
Terminal=false
Type=Application
Categories=Game;
EOF

    rm -rf "$TMP_DIR"

    echo
    echo -e "${GREEN}Vintage Story installed successfully!${NC}"

    if [ -n "$VERSION" ]; then
        echo -e "${GREEN}Version: $VERSION${NC}"
    fi
}

uninstall_game() {

    echo

    if ! is_installed; then
        echo -e "${RED}Vintage Story is not installed.${NC}"
        return
    fi

    echo -e "${YELLOW}Installed version: $(get_version)${NC}"
    echo

    read -rp "Remove Vintage Story? [y/N]: " CONFIRM

    case "$CONFIRM" in
        y|Y)

            echo -e "${BLUE}Removing files...${NC}"

            sudo rm -rf "$INSTALL_DIR"
            sudo rm -f "$DESKTOP_FILE"

            echo
            echo -e "${GREEN}Vintage Story removed.${NC}"
            ;;

        *)

            echo
            echo -e "${YELLOW}Cancelled.${NC}"
            ;;
    esac
}

show_status() {

    echo

    if is_installed; then
        echo -e "Status : ${GREEN}Installed${NC}"
        echo -e "Version: ${GREEN}$(get_version)${NC}"
    else
        echo -e "Status : ${RED}Not installed${NC}"
    fi

    echo
}

while true
do

    clear

    echo "=================================="
    echo "      Vintage Story Manager"
    echo "=================================="

    show_status

    echo "1) Install / Update"
    echo "2) Uninstall"
    echo "3) Exit"

    echo

    read -rp "Select: " CHOICE

    case "$CHOICE" in

        1)
            install_game
            read -rp "Press Enter..."
            ;;

        2)
            uninstall_game
            read -rp "Press Enter..."
            ;;

        3)
            exit 0
            ;;

        *)
            echo
            echo "Invalid option."
            sleep 1
            ;;
    esac

done
