# Smart Glasses Project

This project implements a "Smart Glasses" system using a Raspberry Pi with distance sensing and camera capabilities. The system is designed to alert the user when objects are detected within close proximity, making it potentially useful as an assistive device for people with visual impairments.

## Hardware Requirements

- Raspberry Pi (3 or 4 recommended)
- Raspberry Pi Camera Module or compatible camera
- HC-SR04 Ultrasonic Distance Sensor
- Small vibration motor (any 3-5V DC motor with eccentric weight)
- Push button
- Monitor/display (for setup and demonstration)
- Breadboard and jumper wires
- Power supply (battery pack for portability)
- Bluetooth speaker (optional, for improved audio alerts)

## Setup Instructions

1. Connect the hardware components:
   - HC-SR04 Sensor: 
     - VCC to 5V
     - GND to GND
     - TRIG to GPIO 23
     - ECHO to GPIO 24 (with voltage divider if using 5V sensor with 3.3V Pi)
   - Vibration Motor:
     - Positive to GPIO 18 (via transistor if using higher current motor)
     - Negative to GND
   - Button:
     - One terminal to GPIO 27
     - Other terminal to GND

2. Install required dependencies:
   ```bash
   sudo apt update
   sudo apt install python3-pip python3-opencv espeak
   pip3 install picamera2 RPi.GPIO
   ```

3. Run the program:
   ```bash
   python3 smart_glasses.py
   ```

## Bluetooth Speaker Setup (Optional)

For better audio alerts, you can connect a Bluetooth speaker to the Smart Glasses system:

### Required Software

First, ensure you have the necessary Bluetooth packages installed on your Raspberry Pi:

```bash
sudo apt update
sudo apt install -y bluez bluez-tools pulseaudio pulseaudio-module-bluetooth pulseaudio-utils alsa-utils
```

The setup script will attempt to install missing dependencies, but it's good practice to install them ahead of time.

### Pairing and Configuration

1. Make sure the Bluetooth speaker is charged and in pairing mode
2. Run the included Bluetooth setup script:
   ```bash
   ./setup_bluetooth.sh
   ```
3. Follow the interactive menu to:
   - Scan for Bluetooth devices (option 1)
   - Pair with your speaker (option 2)
   - Connect to the speaker (option 3)
   - Save the speaker's MAC address (option 7)
   - Test the Smart Glasses with the Bluetooth speaker (option 9)

4. For automatic connection at startup, you can add this to your Raspberry Pi's startup scripts:
   ```bash
   /path/to/setup_bluetooth.sh connect
   ```

### Troubleshooting Bluetooth

If you experience issues with Bluetooth:

1. Ensure PulseAudio is running: `pulseaudio --start`
2. Restart the Bluetooth service: `sudo systemctl restart bluetooth`
3. Make sure your user is in the Bluetooth group: `sudo usermod -a -G bluetooth $USER`
4. For permission issues: `sudo chmod 777 /var/run/sdp`

## Features

1. **Distance sensing**: Uses an ultrasonic sensor to detect objects up to several meters away
2. **Visual feedback**: Camera feed displayed with real-time distance measurements
3. **Tactile feedback**: Vibration motor activates when objects are detected within 40cm
4. **Audio alerts**: Text-to-speech announcements when objects are detected
5. **Toggle functionality**: System can be turned on/off using a physical button
6. **Timeout protection**: Prevents the system from hanging if sensor readings fail
7. **Bluetooth audio support**: Optional connection to Bluetooth speakers for better sound quality

## How It Works

1. When started, the system initializes in the OFF state
2. Press the button to turn the system ON
3. The system continuously:
   - Measures distance to objects in front using ultrasonic sensor
   - Displays the camera feed with distance overlay
   - If an object is detected within 40cm:
     - Activates the vibration motor
     - Announces "object detected" via text-to-speech (only once per detection)
   - When objects move beyond 40cm, turns off the vibration and resets alert
4. Press the button again to turn the system OFF
5. Press 'q' while the camera window is in focus to exit the program

## Code Structure

- **Pin Configuration**: Clear definitions for GPIO pins used by components
- **Camera Setup Function**: Initializes the PiCamera in a reusable way
- **speak()**: Improved text-to-speech function with error handling
- **get_distance()**: Enhanced distance measurement with timeout protection
- **main()**: Well-structured main loop with proper exception handling
- **Cleanup**: Ensures all resources are properly released on exit

## Customization

The code can be easily modified to:
- Change the detection distance (currently 40cm)
- Adjust the camera resolution
- Add different types of alerts
- Integrate with other sensors (e.g., add an IR sensor for better detection)

You can edit the `config.json` file (created by the Bluetooth setup script) to customize some settings:
- `detection_distance_cm`: Change the detection threshold (default: 40)
- `camera_resolution`: Adjust camera width and height
- `bluetooth_speaker`: MAC address of your paired Bluetooth speaker

## Troubleshooting

- If the ultrasonic sensor readings are inconsistent, check the wiring and ensure there are no obstructions
- For text-to-speech issues, verify that espeak is installed correctly
- If the program hangs, try adjusting the timeout values in the get_distance() function
- For Bluetooth speaker problems, run `./setup_bluetooth.sh` and use the troubleshooting options

## Future Improvements

- Add a second ultrasonic sensor for better spatial awareness
- Implement computer vision for object recognition
- Create a more compact wearable design
- Add Bluetooth connectivity for smartphone integration 