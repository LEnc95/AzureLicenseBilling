from flask import Flask, jsonify, send_from_directory
import pandas as pd

app = Flask(__name__)

@app.route('/api/licenses', methods=['GET'])
def get_license_data():
    # Load the CSV data
    file_path = r"C:\Users\914476\Documents\Github\AzureLicenseBilling\dat\licenseData.csv"
    data = pd.read_csv(file_path)
    # Convert the data to JSON format
    return jsonify(data.to_dict(orient='records'))

# Add a route to serve the HTML page
@app.route('/', methods=['GET'])
def serve_homepage():
    return send_from_directory('.', 'index.html')

if __name__ == '__main__':
    app.run(debug=True)
