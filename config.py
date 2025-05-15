import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

class Config:
    # Flask settings
    SECRET_KEY = os.getenv('SECRET_KEY', 'your-secret-key-here')
    
    # Azure AD settings
    AZURE_AD_CLIENT_ID = os.getenv('AZURE_AD_CLIENT_ID')
    AZURE_AD_CLIENT_SECRET = os.getenv('AZURE_AD_CLIENT_SECRET')
    AZURE_AD_TENANT_ID = os.getenv('AZURE_AD_TENANT_ID')
    
    # Application settings
    REDIRECT_URI = 'https://msbilling/oauth2/callback'
    LOGOUT_URI = 'https://msbilling/logout'
    
    # Security group settings
    ALLOWED_GROUP_ID = os.getenv('ALLOWED_GROUP_ID')  # License Tracker Users group ID
    
    # Secret Server settings
    SECRET_SERVER_URL = os.getenv('SECRET_SERVER_URL')
    SECRET_SERVER_USERNAME = os.getenv('SECRET_SERVER_USERNAME')
    SECRET_SERVER_PASSWORD = os.getenv('SECRET_SERVER_PASSWORD')
    SECRET_ID_AZURE_CREDENTIALS = os.getenv('SECRET_ID_AZURE_CREDENTIALS') 