from flask import Flask, jsonify, send_from_directory
import os
import json

app = Flask(__name__)

@app.route('/api/licenses', methods=['GET'])
def get_license_data():
    json_path = os.path.join(app.root_path, 'dat', 'billingData.json')
    try:
        with open(json_path, 'r', encoding='utf-8-sig') as f:
            data = json.load(f)
        return jsonify(data)
    except Exception as e:
        return jsonify({'error': f'Error reading billingData.json: {str(e)}'}), 500

@app.route('/', methods=['GET'])
def serve_homepage():
    return send_from_directory('.', 'index.html')

@app.route('/static/<path:filename>')
def serve_static(filename):
    return send_from_directory('static', filename)

if __name__ == '__main__':
    app.run(debug=True)
