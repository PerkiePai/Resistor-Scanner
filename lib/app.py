from flask import Flask, request, jsonify
import cv2
import numpy as np
import base64
from scipy.spatial import distance
import time

app = Flask(__name__)

@app.route('/server', methods=['GET','POST'])

def processImage():
#Process
    base64_string = request.form.get('picture')
    # Decode base64 string to img using base64 and cv2
    decoded_bytes = base64.b64decode(base64_string)
    nparr = np.frombuffer(decoded_bytes, np.uint8)
    image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    
    # Convert the image from BGR to HSV color space
    hsv_image = cv2.cvtColor(image, cv2.COLOR_BGR2HSV)
    # Process the frame to find resistor value
    start_y = hsv_image.shape[0] // 2 - 265
    end_y = hsv_image.shape[0] // 2 - 235
    start_x = hsv_image.shape[1] // 2 - 65
    end_x = hsv_image.shape[1] // 2 + 65

    submat = hsv_image[start_y: end_y, start_x : end_x] # [height, width]

    resistor_locations = find_locations(submat)

    if len(resistor_locations) >= 3:
        # Recover the resistor value
        k_tens = list(resistor_locations.keys())[0]
        k_units = list(resistor_locations.keys())[1]
        k_power = list(resistor_locations.keys())[2]

        value = 10 * resistor_locations[k_tens] + resistor_locations[k_units]
        value *= 10 ** resistor_locations[k_power]

        value_str = ''
        if value >= 1e3 and value < 1e6:
            value_str = f"{value / 1e3} KOhm"
            return value_str
        elif value >= 1e6:
            value_str = f"{value / 1e6} MOhm"
            return value_str
        else:
            value_str = f"{value} Ohm"
            return value_str
 
    return " "
    

# Function to find color bands and their centroids
def find_locations(search_mat):
    locations = {}
    areas = {}

# HSV color bounds for resistor color bands
    COLOR_BOUNDS = [
        [(0, 0, 0), (180, 250, 50)],         # black
        [(0, 90, 10), (15, 250, 100)],       # brown
        [(0, 0, 0), (0, 0, 0)],              # red (defined by two bounds)
        [(4, 100, 100), (9, 250, 150)],      # orange
        [(20, 130, 100), (30, 250, 160)],    # yellow
        [(45, 50, 60), (72, 250, 150)],      # green
        [(80, 50, 50), (106, 250, 150)],     # blue
        [(130, 40, 50), (155, 250, 150)],    # purple
        [(0, 0, 50), (180, 50, 80)],         # gray
        [(0, 0, 90), (180, 15, 140)]         # white
    ]

    # HSV color bounds for red (wraps around in HSV)
    LOWER_RED1 = (0, 65, 100)
    UPPER_RED1 = (2, 250, 150)
    LOWER_RED2 = (171, 65, 50)
    UPPER_RED2 = (180, 250, 150)

    for i in range(len(COLOR_BOUNDS)):
        lower_bound, upper_bound = COLOR_BOUNDS[i]
        if i == 2:
            # Combine the two red ranges
            mask1 = cv2.inRange(search_mat, LOWER_RED1, UPPER_RED1)
            mask2 = cv2.inRange(search_mat, LOWER_RED2, UPPER_RED2)
            mask = cv2.bitwise_or(mask1, mask2)
        else:
            mask = cv2.inRange(search_mat, np.array(lower_bound), np.array(upper_bound))

        contours, _ = cv2.findContours(mask, cv2.RETR_LIST, cv2.CHAIN_APPROX_SIMPLE)

        for contour in contours:
            area = cv2.contourArea(contour)
            if area > 20:
                M = cv2.moments(contour)
                cx = int(M["m10"] / M["m00"])

                if cx not in areas or area > areas[cx]:
                    areas[cx] = area
                    locations[cx] = i

    return locations

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000)
