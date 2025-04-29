# Smart Glasses Project: Simple Explanation

## What are these "Smart Glasses"?

This project is a simple assistive device that helps detect objects in front of a person. It's designed to be especially helpful for people with visual impairments. The system uses a small computer (Raspberry Pi) with sensors and a camera to detect nearby objects and alert the user.

## How do they work?

The smart glasses work like this:

1. A distance sensor constantly measures how far away objects are
2. When an object gets too close (within 40 centimeters or about 16 inches), the system:
   - Makes the glasses vibrate
   - Announces "object detected" using sound
3. A button lets the user turn the system on or off
4. A camera shows what's in front of the user on a small display (for demonstration purposes)

## What are the main parts?

The system uses:
- A Raspberry Pi (a credit-card sized computer)
- A camera to see what's in front
- An ultrasonic sensor (like what bats use) to measure distance
- A small vibration motor to provide feedback
- A button to control the system
- A speaker for audio alerts

## Files in this project

- **smart_glasses.py**: The main program that runs everything
- **setup_bluetooth.sh**: A helper script to connect a Bluetooth speaker
- **smart_glasses.service**: A file that helps the program start automatically when the Raspberry Pi turns on
- **raspberry_pi_boot_setup.txt**: Instructions for making the system start when powered on
- **README.md**: Detailed instructions and information for setting up the project
- **oldcode.py**: An earlier version of the program (not used anymore)

## How is the code organized?

The main program (smart_glasses.py) has several parts:
1. **Setup**: Gets all the components ready to work
2. **Distance measurement**: Uses sound waves to detect how far away objects are
3. **Feedback system**: Controls the vibration and sound alerts
4. **Main loop**: Continuously checks for objects and responds accordingly
5. **Cleanup**: Makes sure everything shuts down properly when you quit

## How to use it

1. Power on the Raspberry Pi with all components connected
2. The system starts in OFF mode
3. Press the button once to turn it ON
4. Move around - the glasses will vibrate and announce when objects are close
5. Press the button again to turn it OFF
6. You can connect a Bluetooth speaker for better sound using the included setup script

## Possible improvements

The system could be enhanced by:
- Adding more sensors for better awareness
- Making it recognize different types of objects
- Creating a more compact, wearable design
- Adding smartphone connectivity 