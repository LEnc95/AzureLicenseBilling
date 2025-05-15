import os
import requests
from requests_ntlm import HttpNtlmAuth
import logging
from typing import Dict, Optional
from urllib3.exceptions import InsecureRequestWarning
import urllib3
import json

# Disable SSL warnings for internal certificates
urllib3.disable_warnings(InsecureRequestWarning)

# Configure logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

class SecretManager:
    def __init__(self, secret_server_url: str, secret_id: int, use_tls12: bool = True):
        self.secret_server_url = secret_server_url.rstrip('/')
        self.secret_id = secret_id
        self.use_tls12 = use_tls12
        self._session = requests.Session()
        self._session.verify = False  # Disable SSL verification for internal certificates
        
        # Use NTLM authentication with current user's credentials
        self._session.auth = HttpNtlmAuth('', '')  # Empty credentials will use current user's context
        
        if use_tls12:
            self._session.mount('https://', requests.adapters.HTTPAdapter(
                max_retries=3,
                pool_connections=100,
                pool_maxsize=100
            ))

    def get_secret(self, secret_name):
        """
        Retrieve a secret from Secret Server using Windows Authentication
        """
        try:
            # Use the same endpoint as your PowerShell script
            url = f"{self.secret_server_url}/winauthwebservices/api/v1/secrets/{self.secret_id}"
            
            # Use Windows Authentication
            response = requests.get(
                url,
                auth=HTTPBasicAuth('', ''),  # Empty credentials for Windows Auth
                verify=True
            )
            response.raise_for_status()
            
            # Parse the response to find the secret
            secret_data = response.json()
            for item in secret_data.get('items', []):
                if item.get('slug') == secret_name:
                    return item.get('itemValue')
            
            self.logger.error(f"Secret {secret_name} not found in Secret Server response")
            return None
            
        except Exception as e:
            self.logger.error(f"Error retrieving secret {secret_name}: {str(e)}")
            return None

    def get_azure_credentials(self) -> Dict[str, str]:
        """
        Retrieve Azure AD credentials from Secret Server.
        Returns a dictionary containing client_id, client_secret, and tenant_id.
        """
        try:
            api_url = f"{self.secret_server_url}/winauthwebservices/api/v1/secrets/{self.secret_id}"
            response = self._session.get(api_url)
            response.raise_for_status()
            secret_details = response.json()
            credentials = {}
            for item in secret_details.get('items', []):
                if item.get('slug') in ['clientid', 'clientsecret', 'tenantid']:
                    credentials[item['slug']] = item['itemValue']
            required_keys = ['clientid', 'clientsecret', 'tenantid']
            missing_keys = [key for key in required_keys if key not in credentials]
            if missing_keys:
                logger.error(f"Missing required credentials: {', '.join(missing_keys)}")
                raise ValueError(f"Missing required credentials: {', '.join(missing_keys)}")
            logger.info("Successfully retrieved Azure credentials.")
            return {
                'client_id': credentials['clientid'],
                'client_secret': credentials['clientsecret'],
                'tenant_id': credentials['tenantid']
            }
        except requests.exceptions.RequestException as e:
            logger.error(f"Request failed: {str(e)}")
            raise Exception(f"Failed to retrieve credentials from Secret Server: {str(e)}")
        except Exception as e:
            logger.error(f"Error processing response: {str(e)}")
            raise Exception(f"Error processing Secret Server response: {str(e)}")

    def get_access_token(self) -> str:
        """
        Get an access token using the client credentials flow.
        Returns the access token as a string.
        """
        try:
            credentials = self.get_azure_credentials()
            token_endpoint = f"https://login.microsoftonline.com/{credentials['tenant_id']}/oauth2/v2.0/token"
            data = {
                'client_id': credentials['client_id'],
                'client_secret': credentials['client_secret'],
                'scope': 'https://graph.microsoft.com/.default',
                'grant_type': 'client_credentials'
            }
            response = self._session.post(token_endpoint, data=data)
            response.raise_for_status()
            logger.info("Successfully obtained access token.")
            return response.json()['access_token']
        except Exception as e:
            logger.error(f"Failed to obtain access token: {str(e)}")
            raise Exception(f"Failed to obtain access token: {str(e)}")

# Example usage:
if __name__ == "__main__":
    # These values should come from environment variables in production
    secret_server_url = os.getenv('SECRET_SERVER_URL', 'https://creds.gianteagle.com/SecretServer')
    secret_id = int(os.getenv('SECRET_ID_AZURE_CREDENTIALS', '42813'))
    
    try:
        secret_manager = SecretManager(secret_server_url, secret_id)
        access_token = secret_manager.get_access_token()
        print("Successfully obtained access token")
    except Exception as e:
        print(f"Error: {str(e)}") 