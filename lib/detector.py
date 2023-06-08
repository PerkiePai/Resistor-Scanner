import sqlite3
import cv2
import numpy as np


# Connect to the SQLite database
conn = sqlite3.connect('database.db')

# Create a cursor object
cursor = conn.cursor()

# Execute a query
cursor.execute('SELECT * FROM your_table')

# Fetch the data
rows = cursor.fetchall()

# Process the data
for row in rows:
    print(row)

# Close the cursor and the database connection
cursor.close()
conn.close()