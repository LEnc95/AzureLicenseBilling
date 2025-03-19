from flask import Flask, jsonify, send_from_directory, render_template
import pandas as pd

app = Flask(__name__)

# Route to serve the API data
@app.route('/api/licenses', methods=['GET'])
def get_license_data():
    # Load the CSV data
    file_path = r"C:\Users\914476\Documents\Github\AzureLicenseBilling\dat\licenseData.csv"
    data = pd.read_csv(file_path)
    # Convert the data to JSON format
    return jsonify(data.to_dict(orient='records'))

# Route to serve the HTML page
@app.route('/', methods=['GET'])
def serve_homepage():
    return send_from_directory('.', 'index.html')

# Enable serving of static files like styles.css
@app.route('/static/<path:filename>')
def serve_static(filename):
    return send_from_directory('static', filename)

if __name__ == '__main__':
    app.run(debug=True)
