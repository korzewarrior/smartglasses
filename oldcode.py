import RPi.GPIO as GPIO
import time
from picamera2 import Picamera2
import cv2
#import pygame
import runprocess

# ========== Pin Assignments ==========
TRIG = 23
ECHO = 24
VIBRATION = 18
BUTTON = 27

# ========== GPIO Setup ==========
GPIO.setmode(GPIO.BCM)
GPIO.setup(TRIG, GPIO.OUT)
GPIO.setup(ECHO, GPIO.IN)
GPIO.setup(VIBRATION, GPIO.OUT)
GPIO.setup(BUTTON, GPIO.IN, pull_up_down=GPIO.PUD_UP)  # Button is active LOW

system_on = False
alert_active = False  # Flag to prevent repeated sound playing

# ========== Camera Setup ==========
picam2 = Picamera2()
preview_config = picam2.create_preview_configuration(main={"format": "XRGB8888", "size": (640, 480)})
picam2.configure(preview_config)
picam2.start()

# ========== Sound Setup ==========
#pygame.mixer.init()
#alertsound = pygame.mixer.Sound('/home/pic11/Desktop/Arizona State University.wav')

# Text to speech function
def speak(text):
    text = text.replace(" ", "")
    subprocess.run(("espeak "" + text +"" 2</dev/null").split(" "))


# ========== Distance Measurement ==========
def get_distance():
    GPIO.output(TRIG, False)
    time.sleep(0.05)

    GPIO.output(TRIG, True)
    time.sleep(0.00001)
    GPIO.output(TRIG, False)

    pulse_start = time.time()
    while GPIO.input(ECHO) == 0:
        pulse_start = time.time()

    while GPIO.input(ECHO) == 1:
        pulse_end = time.time()

    pulse_duration = pulse_end - pulse_start
    distance = (pulse_duration * 34300) / 2  # in cm
    return round(distance, 2)

# ========== Main Loop ==========
try:
    print("Press the button to toggle system ON/OFF.")

    while True:
        # Check for button press
        if GPIO.input(BUTTON) == GPIO.LOW:
            system_on = not system_on
            print("System ON" if system_on else "System OFF")
            time.sleep(0.5)  # Debounce

        # Capture camera frame
        frame = picam2.capture_array()

        if system_on:
            dist = get_distance()
            print(f"Distance: {dist} cm")

            # Show distance
            cv2.putText(frame, f"Distance: {dist} cm", (10, 30),
                        cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2)

            if dist < 40:
                GPIO.output(VIBRATION, True)

                if not alert_active:
                    alert_active = True
                    #alert_sound.play()
    speak("object detected")
            else:
                GPIO.output(VIBRATION, False)
                alert_active = False  # Reset so it can trigger again next time
        else:
            GPIO.output(VIBRATION, False)
            alert_active = False
            cv2.putText(frame, "System OFF", (10, 30),
                        cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 0, 255), 2)

        # Show camera feed
        cv2.imshow("Smart Glasses Camera Feed", frame)

        # Exit on 'q'
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

except KeyboardInterrupt:
    print("Stopped by user.")

finally:
    GPIO.cleanup()
    cv2.destroyAllWindows()
    #pygame.quit()
    picam2.close() 