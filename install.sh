#!/usr/bin/env bash

# ecs-exec installer script
# Installs the utility to the user's local bin directory

set -e

SCRIPT_NAME="ecs-exec"
SOURCE_URL="https://raw.githubusercontent.com/cyqlelabs/ecs-exec/main/ecs-exec.sh"
USER_BIN_DIR="$HOME/.local/bin"

# Create user bin directory if it doesn't exist
if [ ! -d "$USER_BIN_DIR" ]; then
    echo "Creating directory $USER_BIN_DIR..."
    mkdir -p "$USER_BIN_DIR"
fi

# Check if the directory is in PATH
if [[ ":$PATH:" != *":$USER_BIN_DIR:"* ]]; then
    echo "Warning: $USER_BIN_DIR is not in your PATH."
    echo "Consider adding the following line to your ~/.bashrc or ~/.zshrc:"
    echo "  export PATH=\"\$PATH:$USER_BIN_DIR\""
fi

# Check if local copy of the script exists or download from GitHub
LOCAL_SCRIPT="./ecs-exec.sh"
if [ -f "$LOCAL_SCRIPT" ]; then
    echo "Installing $SCRIPT_NAME from local file $LOCAL_SCRIPT to $USER_BIN_DIR/$SCRIPT_NAME..."
    cp "$LOCAL_SCRIPT" "$USER_BIN_DIR/$SCRIPT_NAME"
else
    echo "Downloading and installing $SCRIPT_NAME from GitHub to $USER_BIN_DIR/$SCRIPT_NAME..."
    curl -s "$SOURCE_URL" -o "$USER_BIN_DIR/$SCRIPT_NAME"
fi
chmod +x "$USER_BIN_DIR/$SCRIPT_NAME"

# Check for dependencies
echo "Checking dependencies..."

MISSING_DEPS=()

# Check for AWS CLI
if ! command -v aws &> /dev/null; then
    MISSING_DEPS+=("aws-cli")
fi

# Check for jq
if ! command -v jq &> /dev/null; then
    MISSING_DEPS+=("jq")
fi

# If dependencies are missing, provide instructions
if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
    echo "The following dependencies are missing: ${MISSING_DEPS[*]}"
    
    # Check the distribution
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO="$ID"
        echo "Detected Linux distribution: $DISTRO"
        
        case "$DISTRO" in
            ubuntu|debian|pop|mint|elementary|zorin)
                echo "To install missing dependencies:"
                if [[ " ${MISSING_DEPS[*]} " =~ " aws-cli " ]]; then
                    echo "For AWS CLI, follow the official installation guide:"
                    echo "https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
                fi
                if [[ " ${MISSING_DEPS[*]} " =~ " jq " ]]; then
                    echo "For jq: sudo apt-get update && sudo apt-get install -y jq"
                fi
                ;;
            fedora|rhel|centos|rocky|almalinux|ol)
                echo "To install missing dependencies:"
                if [[ " ${MISSING_DEPS[*]} " =~ " aws-cli " ]]; then
                    echo "For AWS CLI, follow the official installation guide:"
                    echo "https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
                fi
                if [[ " ${MISSING_DEPS[*]} " =~ " jq " ]]; then
                    echo "For jq: sudo dnf install -y jq or sudo yum install -y jq"
                fi
                ;;
            arch|manjaro|endeavouros)
                echo "To install missing dependencies:"
                if [[ " ${MISSING_DEPS[*]} " =~ " aws-cli " ]]; then
                    echo "For AWS CLI: sudo pacman -S --needed --noconfirm aws-cli"
                fi
                if [[ " ${MISSING_DEPS[*]} " =~ " jq " ]]; then
                    echo "For jq: sudo pacman -S --needed --noconfirm jq"
                fi
                ;;
            opensuse|suse)
                echo "To install missing dependencies:"
                if [[ " ${MISSING_DEPS[*]} " =~ " aws-cli " ]]; then
                    echo "For AWS CLI, follow the official installation guide:"
                    echo "https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
                fi
                if [[ " ${MISSING_DEPS[*]} " =~ " jq " ]]; then
                    echo "For jq: sudo zypper install -y jq"
                fi
                ;;
            *)
                echo "To install missing dependencies on your distribution:"
                echo "For AWS CLI: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
                echo "For jq: https://stedolan.github.io/jq/download/"
                ;;
        esac
    else
        echo "To install missing dependencies:"
        echo "For AWS CLI: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
        echo "For jq: https://stedolan.github.io/jq/download/"
    fi
fi

echo "Installation complete!"
echo "You can now run the utility by typing '$SCRIPT_NAME' in your terminal."

# Verify installation
if [[ ":$PATH:" == *":$USER_BIN_DIR:"* ]] && command -v "$SCRIPT_NAME" &> /dev/null; then
    echo "Verification successful: $SCRIPT_NAME is now available in your PATH."
else
    echo "Note: You may need to open a new terminal or run the following command to use $SCRIPT_NAME:"
    echo "  export PATH=\"\$PATH:$USER_BIN_DIR\""
fi

# Check AWS configuration
if ! aws configure list &> /dev/null; then
    echo ""
    echo "Note: AWS CLI does not appear to be configured yet."
    echo "Please run 'aws configure' to set up your AWS credentials."
fi

exit 0
