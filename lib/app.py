from flask import Flask, request
import cv2
import numpy as np

app = Flask(__name__)

@app.route('/server', methods=['GET','POST'])
def processImage():
    if (request.method == 'POST'):
        ImageBase64 = request.form.get('picture')
        #Process
        wattage = '100'
        #Respond
        response_data = {'wattage': wattage}
    else:
        # If the request method is not POST, handle the error appropriately
        # For example, you might raise an exception or return an error message.
        error_message = "Error: Invalid request method. Expected 'POST' method."
        return {'error': error_message}
    return response_data 

if __name__ == '__main__':
    app.run()
