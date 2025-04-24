#!/bin/bash
# Bluetooth Speaker Setup Script for Smart Glasses
# This script helps pair, connect, and configure a Bluetooth speaker for audio output

# Get the script directory (where this script is located)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CONFIG_FILE="$SCRIPT_DIR/config.json"

echo "Smart Glasses Bluetooth Speaker Setup"
echo "===================================="

# Check if configuration file exists, create if not
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Creating config file..."
    echo '{
    "bluetooth_speaker": "",
    "detection_distance_cm": 40,
    "camera_resolution": {
        "width": 640,
        "height": 480
    }
}' > "$CONFIG_FILE"
    echo "Created config.json"
fi

# Check if Bluetooth service is running
if ! systemctl is-active --quiet bluetooth; then
    echo "Starting Bluetooth service..."
    sudo systemctl start bluetooth
    sleep 2
fi

# Check if required packages are installed
check_dependencies() {
    PACKAGES_TO_INSTALL=""
    
    # Check for bluetoothctl
    if ! command -v bluetoothctl &> /dev/null; then
        PACKAGES_TO_INSTALL="$PACKAGES_TO_INSTALL bluez"
    fi
    
    # Check for pulseaudio utils
    if ! command -v pactl &> /dev/null; then
        PACKAGES_TO_INSTALL="$PACKAGES_TO_INSTALL pulseaudio-utils"
    fi
    
    # Check for test sounds
    if ! command -v aplay &> /dev/null; then
        PACKAGES_TO_INSTALL="$PACKAGES_TO_INSTALL alsa-utils"
    fi
    
    # Install missing packages if any
    if [ -n "$PACKAGES_TO_INSTALL" ]; then
        echo "Installing required packages: $PACKAGES_TO_INSTALL"
        sudo apt-get update
        sudo apt-get install -y $PACKAGES_TO_INSTALL
    fi
}

# Function to update config file with speaker MAC
update_config_file() {
    local mac="$1"
    
    if [ -f "$CONFIG_FILE" ]; then
        # Create a backup of the config file
        cp "$CONFIG_FILE" "${CONFIG_FILE}.bak"
        
        # Check if bluetooth_speaker field exists and update
        if grep -q "bluetooth_speaker" "$CONFIG_FILE"; then
            # Update existing field
            sed -i "s/\"bluetooth_speaker\": \"[^\"]*\"/\"bluetooth_speaker\": \"$mac\"/" "$CONFIG_FILE"
        else
            # Add the field if it doesn't exist (unlikely with our template)
            sed -i "s/{/{\"bluetooth_speaker\": \"$mac\",/" "$CONFIG_FILE"
        fi
        
        echo "Updated config.json with speaker MAC address: $mac"
        
        # Also ensure Bluetooth service starts at boot
        echo "Enabling Bluetooth service to start at boot..."
        sudo systemctl enable bluetooth
    else
        echo "Error: config.json not found at $CONFIG_FILE"
        exit 1
    fi
}

# Function to connect to a Bluetooth speaker
connect_to_speaker() {
    local mac="$1"
    echo "Attempting to connect to Bluetooth speaker: $mac"
    
    # Try to connect to the speaker
    bluetoothctl connect "$mac"
    
    # Wait for connection to establish
    sleep 2
    
    # Set as default audio output
    echo "Setting Bluetooth speaker as default audio output..."
    CARD_ID=$(pactl list cards short | grep bluez | awk '{print $1}')
    if [ -n "$CARD_ID" ]; then
        pactl set-card-profile $CARD_ID a2dp_sink
        SINK_ID=$(pactl list sinks short | grep bluez | awk '{print $1}')
        if [ -n "$SINK_ID" ]; then
            pactl set-default-sink $SINK_ID
            echo "Bluetooth speaker set as default audio device"
            
            # Test the audio
            echo "Playing a test sound..."
            aplay /usr/share/sounds/alsa/Front_Center.wav 2>/dev/null || \
            paplay /usr/share/sounds/freedesktop/stereo/complete.oga 2>/dev/null || \
            echo "Could not find test sounds. Try installing alsa-utils or pulseaudio-utils"
            
            return 0
        else
            echo "No Bluetooth sink found"
            return 1
        fi
    else
        echo "No Bluetooth card found. Make sure your speaker is connected."
        return 1
    fi
}

# Update the Smart Glasses code to use this speaker
update_smart_glasses_audio() {
    if [ -f "$SCRIPT_DIR/smart_glasses.py" ]; then
        echo "Testing espeak audio via Bluetooth speaker..."
        # Run espeak test directly to test Bluetooth output
        echo "Running: espeak \"testing bluetooth speaker\" 2>/dev/null"
        espeak "testing bluetooth speaker" 2>/dev/null
        
        echo "Bluetooth speaker configuration complete!"
        echo "Your Smart Glasses will now use the Bluetooth speaker for audio alerts."
    else
        echo "Warning: Could not find smart_glasses.py in the current directory."
        echo "Make sure you're running this script from the Smart Glasses project root directory."
    fi
}

# Main menu function
show_menu() {
    echo ""
    echo "Choose an option:"
    echo "1. Scan for Bluetooth devices"
    echo "2. Pair with a device"
    echo "3. Connect to a paired device"
    echo "4. List paired devices"
    echo "5. Set as default audio device"
    echo "6. Test audio"
    echo "7. Save speaker MAC to config file"
    echo "8. Connect to saved speaker"
    echo "9. Test Smart Glasses with Bluetooth speaker"
    echo "0. Exit"
    echo ""
    read -p "Enter your choice [0-9]: " choice
    
    case $choice in
        1)
            echo "Scanning for Bluetooth devices (Ctrl+C to stop)..."
            bluetoothctl scan on
            ;;
        2)
            read -p "Enter the MAC address of the device to pair: " mac
            echo "Attempting to pair with $mac..."
            bluetoothctl pair "$mac"
            ;;
        3)
            read -p "Enter the MAC address of the device to connect: " mac
            echo "Attempting to connect to $mac..."
            connect_to_speaker "$mac"
            ;;
        4)
            echo "Paired devices:"
            bluetoothctl devices
            ;;
        5)
            echo "Setting as default audio device..."
            CARD_ID=$(pactl list cards short | grep bluez | awk '{print $1}')
            if [ -n "$CARD_ID" ]; then
                pactl set-card-profile $CARD_ID a2dp_sink
                SINK_ID=$(pactl list sinks short | grep bluez | awk '{print $1}')
                if [ -n "$SINK_ID" ]; then
                    pactl set-default-sink $SINK_ID
                    echo "Bluetooth speaker set as default audio device"
                else
                    echo "No Bluetooth sink found"
                fi
            else
                echo "No Bluetooth card found. Make sure your speaker is connected."
            fi
            ;;
        6)
            echo "Playing test audio..."
            aplay /usr/share/sounds/alsa/Front_Center.wav 2>/dev/null || \
            paplay /usr/share/sounds/freedesktop/stereo/complete.oga 2>/dev/null || \
            echo "Could not find test sounds. Try installing alsa-utils or pulseaudio-utils"
            ;;
        7)
            read -p "Enter the MAC address of your Bluetooth speaker: " mac
            update_config_file "$mac"
            ;;
        8)
            # Get the MAC address from the config file
            SPEAKER_MAC=$(grep -oP '"bluetooth_speaker": "\K[^"]*' "$CONFIG_FILE" 2>/dev/null || echo "")
            if [ -n "$SPEAKER_MAC" ] && [ "$SPEAKER_MAC" != "null" ]; then
                connect_to_speaker "$SPEAKER_MAC"
            else
                echo "No Bluetooth speaker MAC address found in config file."
                echo "Use option 7 to save a speaker MAC first."
            fi
            ;;
        9)
            update_smart_glasses_audio
            ;;
        0)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid option"
            ;;
    esac
    
    # Return to menu after action
    show_menu
}

# Automatic setup (for using as a command-line tool)
auto_setup() {
    check_dependencies
    
    # Get the MAC address from the config file
    SPEAKER_MAC=$(grep -oP '"bluetooth_speaker": "\K[^"]*' "$CONFIG_FILE" 2>/dev/null || echo "")
    
    if [ -n "$SPEAKER_MAC" ] && [ "$SPEAKER_MAC" != "null" ]; then
        connect_to_speaker "$SPEAKER_MAC"
        update_smart_glasses_audio
        exit 0
    else
        echo "No Bluetooth speaker MAC address found in config file."
        echo "Starting interactive setup..."
        # Fall through to interactive menu
    fi
}

# Check for dependencies
check_dependencies

# Check if being run directly or with parameters
if [ $# -eq 0 ]; then
    # Start the interactive menu if no parameters
    show_menu
elif [ "$1" = "connect" ]; then
    # Just connect to the saved speaker
    SPEAKER_MAC=$(grep -oP '"bluetooth_speaker": "\K[^"]*' "$CONFIG_FILE" 2>/dev/null || echo "")
    if [ -n "$SPEAKER_MAC" ] && [ "$SPEAKER_MAC" != "null" ]; then
        connect_to_speaker "$SPEAKER_MAC"
    else
        echo "No Bluetooth speaker MAC address found in config file."
        exit 1
    fi
elif [ "$1" = "auto" ]; then
    # Run automatic setup
    auto_setup
fi 