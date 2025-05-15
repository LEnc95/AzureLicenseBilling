import os
from dotenv import load_dotenv
from secret_manager import SecretManager

# Load environment variables
load_dotenv()

class Config:
    # Flask settings
    SECRET_KEY = os.getenv('SECRET_KEY', 'your-secret-key-here')
    
    # Secret Server settings
    SECRET_SERVER_URL = os.getenv('SECRET_SERVER_URL', 'https://creds.gianteagle.com/SecretServer')
    SECRET_ID_AZURE_CREDENTIALS = int(os.getenv('SECRET_ID_AZURE_CREDENTIALS', '42813'))
    
    # Initialize SecretManager
    _secret_manager = SecretManager(SECRET_SERVER_URL, SECRET_ID_AZURE_CREDENTIALS)
    
    # Get Azure credentials from Secret Server
    try:
        azure_credentials = _secret_manager.get_azure_credentials()
        AZURE_AD_CLIENT_ID = azure_credentials['client_id']
        AZURE_AD_CLIENT_SECRET = azure_credentials['client_secret']
        AZURE_AD_TENANT_ID = azure_credentials['tenant_id']
    except Exception as e:
        print(f"Warning: Failed to retrieve Azure credentials from Secret Server: {str(e)}")
        # Fallback to environment variables if Secret Server fails
        AZURE_AD_CLIENT_ID = os.getenv('AZURE_AD_CLIENT_ID')
        AZURE_AD_CLIENT_SECRET = os.getenv('AZURE_AD_CLIENT_SECRET')
        AZURE_AD_TENANT_ID = os.getenv('AZURE_AD_TENANT_ID')
    
    # Application settings
    REDIRECT_URI = 'https://msbilling/oauth2/callback'
    LOGOUT_URI = 'https://msbilling/logout'
    
    # Security group settings
    ALLOWED_GROUP_ID = os.getenv('ALLOWED_GROUP_ID')  # License Tracker Users group ID
    
    # Secret Server settings
    SECRET_SERVER_USERNAME = os.getenv('SECRET_SERVER_USERNAME')
    SECRET_SERVER_PASSWORD = os.getenv('SECRET_SERVER_PASSWORD') 