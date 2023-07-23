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
    x1, y1 = 535, 690  # Top-left coordinates (x1, y1)
    x2, y2 = 665, 745  # Bottom-right coordinates (x2, y2)
    image = image[y1:y2, x1:x2]
    #Mark the location of the color band
    color_band_1 = image[27, 18]
    color_band_2 = image[27, 44]
    color_band_3 = image[27, 70]
    color_band_4 = image[27, 102]
    print(color_band_1)
    print(color_band_2)
    print(color_band_3)
    print(color_band_4)

#ค่าหลัก 1 10
    color_list_for_band_1_2 = [
        ('0', (90, 90, 90)), #black
        ('1', (90, 115, 150)), #brown
        ('2', (105, 120, 205)), #red
        ('3', (70, 135, 215)), #orange
        ('4', (30, 220, 220)), #yellow
        ('5', (70, 200, 170)), #green
        ('6', (215, 150, 5)), #blue
        ('7', (170, 100, 80)), #purple
        ('8', (150, 150, 140)), #grey
        ('9', (225, 225, 215)), #white
        # ('', (70, 170, 220)), #gold
        # ('', (147, 147, 137)), #silver
    ]
#ตัวคูณ
    color_list_for_band_3 = [
        ('1', (90, 90, 90)), #black
        ('10', (90, 115, 150)), #brown
        ('100', (105, 120, 205)), #red
        ('1000', (70, 135, 215)), #orange
        ('10000', (30, 220, 220)), #yellow
        ('100000', (70, 200, 170)), #green
        ('1000000', (215, 150, 5)), #blue
        ('10000000', (170, 100, 80)), #purple
        # ('', (150, 150, 140)), #grey
        # ('', (225, 225, 215)), #white
        ('0.1', (70, 170, 220)), #gold
        ('0.01', (147, 147, 137)), #silver
    ]
#ค่าคลาดเคลื่อน
    color_list_for_band_4 = [
        # ('', (90, 90, 90)), #black
        ('1', (90, 115, 150)), #brown
        ('2', (105, 120, 205)), #red
        # ('', (70, 135, 215)), #orange
        # ('', (30, 220, 220)), #yellow
        ('0.5', (70, 200, 170)), #green
        ('0.25', (215, 150, 5)), #blue
        ('0.10', (170, 100, 80)), #purple
        ('0.05', (150, 150, 140)), #grey
        # ('', (225, 225, 215)), #white
        ('5', (70, 170, 220)), #gold
        ('10', (147, 147, 137)), #silver
    ]

    closest_color_name_1 = float(rgb_to_closest_color(color_band_1, color_list_for_band_1_2))
    closest_color_name_2 = float(rgb_to_closest_color(color_band_2, color_list_for_band_1_2))
    closest_color_name_3 = float(rgb_to_closest_color(color_band_3, color_list_for_band_3))
    closest_color_name_4 = float(rgb_to_closest_color(color_band_4, color_list_for_band_4)
)
    wattage_raw_value = int((closest_color_name_1*10+closest_color_name_2)*closest_color_name_3 )
    # tolerance = float(wattage_raw_value + "±" + (closest_color_name_4*wattage_raw_value)/100)

    #Respond
    response_data = str(wattage_raw_value)
    print ("value: ", response_data) 
    return response_data

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
