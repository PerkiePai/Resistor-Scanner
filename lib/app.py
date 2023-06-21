import cv2
import numpy as np
import base64

def convert_video_string_to_image(video_string):
    # Convert the video string to bytes
    video_bytes = base64.b64decode(video_string)

    # Create a video capture object
    video_capture = cv2.VideoCapture()
    video_capture.open(video_bytes)

    # Read the first frame of the video
    success, frame = video_capture.read()

    # If the frame is successfully read, convert it to an image
    if success:
        # Convert the frame to RGB format
        frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)

        # Create an image from the frame
        image = Image.fromarray(frame)

        # Return the image
        return image

    return None

# Example usage
video_string = "your_video_string_here"

# Convert the video string to an image
image = convert_video_string_to_image(video_string)

# Display the image
image.show()

