import os
import requests
from requests.auth import HTTPBasicAuth
import logging

class SecretManager:
    def __init__(self):
        self.secret_server_url = os.getenv('SECRET_SERVER_URL', 'https://creds.gianteagle.com/SecretServer')
        self.secret_id = os.getenv('SECRET_SERVER_ID')
        self.logger = logging.getLogger(__name__)

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

    def get_azure_credentials(self):
        """
        Retrieve all required Azure AD credentials
        """
        return {
            'client_id': self.get_secret('clientId'),
            'client_secret': self.get_secret('clientSecret'),
            'tenant_id': self.get_secret('tenantId'),
            'allowed_group_id': self.get_secret('allowedGroupId')
        } 