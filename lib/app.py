from flask import Flask, request, jsonify
import cv2
import numpy as np
import base64
from scipy.spatial import distance

app = Flask(__name__)

@app.route('/server', methods=['GET','POST'])

def processImage():
#Process
    base64_string = request.form.get('picture')
    # Decode base64 string to img using base64 and cv2
    decoded_bytes = base64.b64decode(base64_string)
    nparr = np.frombuffer(decoded_bytes, np.uint8)
    image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    #Crop to 68mm * 65mm or 1 : 2.36 or 130px * 55px
    x1, y1 = 470, 690  # Top-left coordinates (x1, y1)
    x2, y2 = 600, 745  # Bottom-right coordinates (x2, y2)
    image = image[y1:y2, x1:x2]
    #Mark the location of the color band
    color_band_1 = image[27, 26]
    color_band_2 = image[27, 52]
    color_band_3 = image[27, 78]
    color_band_4 = image[27, 104]

    color_list = [
    ('red', (0, 0, 255)),
    ('green', (0, 255, 0)),
    ('blue', (255, 0, 0)),
    ('yellow', (0, 255, 255)),
    ('purple', (128, 0, 128)),

    ]

    closest_color_name = rgb_to_closest_color(color_band_1, color_list)

    #Respond
    response_data = closest_color_name
    
    return closest_color_name

def rgb_to_closest_color(rgb_value, color_list):
    min_distance = float('inf')
    closest_color = None

    for color_name, color_rgb in color_list:
        dist = distance.euclidean(rgb_value, color_rgb)
        if dist < min_distance:
            min_distance = dist
            closest_color = color_name

    return closest_color

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000)
