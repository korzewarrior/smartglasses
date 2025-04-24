#!/usr/bin/env python3
"""
Smart Glasses System

A Raspberry Pi-based assistive device that detects objects in front of the user
and provides feedback through vibration and audio alerts.
"""

import RPi.GPIO as GPIO
import time
import cv2
import subprocess
from picamera2 import Picamera2

# ========== Pin Assignments ==========
TRIG = 23       # Ultrasonic sensor trigger pin
ECHO = 24       # Ultrasonic sensor echo pin
VIBRATION = 18  # Vibration motor control pin
BUTTON = 27     # Toggle button pin

# ========== GPIO Setup ==========
GPIO.setmode(GPIO.BCM)
GPIO.setup(TRIG, GPIO.OUT)
GPIO.setup(ECHO, GPIO.IN)
GPIO.setup(VIBRATION, GPIO.OUT)
GPIO.setup(BUTTON, GPIO.IN, pull_up_down=GPIO.PUD_UP)  # Button is active LOW (pull-up)

# Initialize system state
system_on = False
alert_active = False  # Flag to prevent repeated sound playing

# ========== Camera Setup ==========
def setup_camera():
    """Initialize and configure the PiCamera"""
    picam = Picamera2()
    preview_config = picam.create_preview_configuration(main={"format": "XRGB8888", "size": (640, 480)})
    picam.configure(preview_config)
    picam.start()
    return picam

# ========== Text to Speech Function ==========
def speak(text):
    """Convert text to speech using espeak"""
    try:
        # Remove spaces for better pronunciation
        text = text.replace(" ", "")
        command = f"espeak \"{text}\" 2>/dev/null"
        subprocess.run(command.split())
    except Exception as e:
        print(f"Text-to-speech error: {e}")

# ========== Distance Measurement ==========
def get_distance():
    """Measure distance using ultrasonic sensor (HC-SR04)
    
    Returns:
        float: Distance in centimeters, rounded to 2 decimal places
    """
    # Ensure trigger is LOW
    GPIO.output(TRIG, False)
    time.sleep(0.05)
    
    # Send 10μs pulse to trigger
    GPIO.output(TRIG, True)
    time.sleep(0.00001)  # 10 microseconds
    GPIO.output(TRIG, False)
    
    # Wait for echo to go HIGH (sound sent)
    pulse_start = time.time()
    timeout_start = time.time()
    while GPIO.input(ECHO) == 0:
        pulse_start = time.time()
        # Add timeout to prevent hanging
        if time.time() - timeout_start > 1:
            return 1000  # Return a large value if timed out
    
    # Wait for echo to go LOW (sound received back)
    pulse_end = time.time()
    timeout_start = time.time()
    while GPIO.input(ECHO) == 1:
        pulse_end = time.time()
        # Add timeout to prevent hanging
        if time.time() - timeout_start > 1:
            return 1000  # Return a large value if timed out
    
    # Calculate distance
    pulse_duration = pulse_end - pulse_start
    # Speed of sound = 343m/s = 34300cm/s
    # Distance = (time × speed of sound) ÷ 2 (round trip)
    distance = (pulse_duration * 34300) / 2  # in cm
    
    return round(distance, 2)

# ========== Main Function ==========
def main():
    """Main function to run the Smart Glasses system"""
    try:
        picam = setup_camera()
        global system_on, alert_active
        
        print("Smart Glasses System Initialized")
        print("Press the button to toggle system ON/OFF.")
        print("Press 'q' to quit.")
        
        while True:
            # Check for button press to toggle system
            if GPIO.input(BUTTON) == GPIO.LOW:  # Button pressed (active LOW)
                system_on = not system_on
                status = "ON" if system_on else "OFF"
                print(f"System turned {status}")
                speak(f"system {status}")
                time.sleep(0.5)  # Debounce delay
            
            # Capture camera frame
            frame = picam.capture_array()
            
            if system_on:
                # Measure distance
                dist = get_distance()
                print(f"Distance: {dist} cm")
                
                # Display distance on frame
                cv2.putText(frame, f"Distance: {dist} cm", (10, 30),
                           cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2)
                
                # Object detection and alerts
                if dist < 40:  # Object within 40cm
                    # Activate vibration
                    GPIO.output(VIBRATION, True)
                    
                    # Play alert sound only once per detection
                    if not alert_active:
                        alert_active = True
                        speak("object detected")
                else:
                    # No object detected, turn off vibration
                    GPIO.output(VIBRATION, False)
                    alert_active = False  # Reset alert flag
            else:
                # System is off
                GPIO.output(VIBRATION, False)
                alert_active = False
                cv2.putText(frame, "System OFF", (10, 30),
                           cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 0, 255), 2)
            
            # Display camera feed
            cv2.imshow("Smart Glasses Camera Feed", frame)
            
            # Check for 'q' key to exit
            if cv2.waitKey(1) & 0xFF == ord('q'):
                break
    
    except KeyboardInterrupt:
        print("\nStopped by user (Ctrl+C).")
    except Exception as e:
        print(f"Error: {e}")
    finally:
        # Clean up resources
        GPIO.cleanup()
        cv2.destroyAllWindows()
        picam.close()
        print("Smart Glasses System Shutdown Complete")

# Run the main function if this script is executed directly
if __name__ == "__main__":
    main() 