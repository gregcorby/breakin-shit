#!/bin/bash

# Godot Export Script for Donkey GTA
# Exports the game for Android and iOS

set -e

PLATFORM=$1
GODOT_VERSION="4.2"
PROJECT_PATH="."
EXPORT_PATH="../android/app/src/main/assets"
IOS_EXPORT_PATH="../ios/main.pck"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Godot is installed
check_godot() {
    if ! command -v godot &> /dev/null; then
        print_error "Godot is not installed or not in PATH"
        print_info "Please install Godot ${GODOT_VERSION} from https://godotengine.org/"
        exit 1
    fi

    print_info "Found Godot: $(godot --version)"
}

# Export for Android
export_android() {
    print_info "Exporting for Android..."

    # Create export directory if it doesn't exist
    mkdir -p "${EXPORT_PATH}"

    # Export as PCK file for Android
    godot --headless --export-pack "Android" "${EXPORT_PATH}/main.pck" --path "${PROJECT_PATH}"

    if [ $? -eq 0 ]; then
        print_info "Android export successful!"
        print_info "Output: ${EXPORT_PATH}/main.pck"
    else
        print_error "Android export failed!"
        exit 1
    fi
}

# Export for iOS
export_ios() {
    print_info "Exporting for iOS..."

    # Create export directory if it doesn't exist
    mkdir -p "$(dirname ${IOS_EXPORT_PATH})"

    # Export as PCK file for iOS
    godot --headless --export-pack "iOS" "${IOS_EXPORT_PATH}" --path "${PROJECT_PATH}"

    if [ $? -eq 0 ]; then
        print_info "iOS export successful!"
        print_info "Output: ${IOS_EXPORT_PATH}"
    else
        print_error "iOS export failed!"
        exit 1
    fi
}

# Main script
main() {
    print_info "=== Donkey GTA Export Script ==="

    if [ -z "$PLATFORM" ]; then
        print_error "Platform not specified!"
        echo "Usage: ./export_game.sh [android|ios|all]"
        exit 1
    fi

    check_godot

    case $PLATFORM in
        android)
            export_android
            ;;
        ios)
            export_ios
            ;;
        all)
            export_android
            export_ios
            ;;
        *)
            print_error "Unknown platform: $PLATFORM"
            echo "Valid platforms: android, ios, all"
            exit 1
            ;;
    esac

    print_info "=== Export Complete ==="
}

main
