from flask import Flask, jsonify, send_from_directory, request, abort
import os
import json
from secret_manager import SecretManager
import requests
from functools import wraps

app = Flask(__name__)

# Initialize SecretManager
secret_server_url = os.getenv('SECRET_SERVER_URL', 'https://creds.gianteagle.com/SecretServer')
secret_id = int(os.getenv('SECRET_ID_AZURE_CREDENTIALS', '42813'))
secret_manager = SecretManager(secret_server_url, secret_id)

# Security group ID - replace with your actual security group ID
REQUIRED_SECURITY_GROUP_ID = os.getenv('REQUIRED_SECURITY_GROUP_ID', 'your-security-group-id')

def require_security_group_membership(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        # Get the access token from the Authorization header
        auth_header = request.headers.get('Authorization')
        if not auth_header or not auth_header.startswith('Bearer '):
            print("No Authorization header or invalid format")
            abort(401, description='No access token provided')
        
        access_token = auth_header.split(' ')[1]
        print(f"Received token: {access_token[:10]}...")
        
        # For debugging, temporarily bypass security group check
        print("Bypassing security group check for debugging")
        return f(*args, **kwargs)
        
        # Commented out security group check for now
        """
        # Get the user's identity from the token
        headers = {'Authorization': f'Bearer {access_token}'}
        try:
            # Get the current user's ID
            user_response = requests.get('https://graph.microsoft.com/v1.0/me', headers=headers)
            user_response.raise_for_status()
            user_id = user_response.json()['id']
            
            # Check if user is a member of the required security group
            group_check_url = f'https://graph.microsoft.com/v1.0/users/{user_id}/memberOf'
            group_response = requests.get(group_check_url, headers=headers)
            group_response.raise_for_status()
            
            # Check if user is a member of the required group
            is_member = any(
                group['id'] == REQUIRED_SECURITY_GROUP_ID 
                for group in group_response.json().get('value', [])
            )
            
            if not is_member:
                abort(403, description='User is not a member of the required security group')
                
            return f(*args, **kwargs)
            
        except requests.exceptions.RequestException as e:
            abort(401, description=f'Error verifying group membership: {str(e)}')
        """
            
    return decorated_function

@app.route('/api/licenses', methods=['GET'])
@require_security_group_membership
def get_license_data():
    json_path = os.path.join(app.root_path, 'dat', 'billingData.json')
    print(f"Attempting to read license data from: {json_path}")
    try:
        with open(json_path, 'r', encoding='utf-8-sig') as f:
            data = json.load(f)
            print(f"Successfully loaded license data with {len(data)} entries")
            if len(data) > 0:
                print(f"First entry keys: {list(data[0].keys())}")
        return jsonify(data)
    except FileNotFoundError:
        print(f"Error: File not found at {json_path}")
        return jsonify({'error': f'License data file not found at {json_path}'}), 404
    except json.JSONDecodeError as e:
        print(f"Error: Invalid JSON in file: {str(e)}")
        return jsonify({'error': f'Invalid JSON in license data file: {str(e)}'}), 500
    except Exception as e:
        print(f"Error reading billingData.json: {str(e)}")
        return jsonify({'error': f'Error reading billingData.json: {str(e)}'}), 500

@app.route('/api/token', methods=['GET'])
def get_token():
    try:
        access_token = secret_manager.get_access_token()
        return jsonify({'access_token': access_token})
    except Exception as e:
        return jsonify({'error': f'Error obtaining access token: {str(e)}'}), 500

@app.route('/api/graph', methods=['GET'])
@require_security_group_membership
def call_graph():
    try:
        access_token = secret_manager.get_access_token()
        # Call Microsoft Graph to get a list of users (requires User.Read.All application permission)
        headers = {'Authorization': f'Bearer {access_token}'}
        response = requests.get('https://graph.microsoft.com/v1.0/users', headers=headers)
        response.raise_for_status()
        return jsonify(response.json())
    except Exception as e:
        return jsonify({'error': f'Error calling Microsoft Graph: {str(e)}'}), 500

@app.route('/', methods=['GET'])
def serve_homepage():
    return send_from_directory('.', 'index.html')

@app.route('/static/<path:filename>')
def serve_static(filename):
    return send_from_directory('static', filename)

if __name__ == '__main__':
    app.run(debug=True)
