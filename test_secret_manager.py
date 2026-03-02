import os
from secret_manager import SecretManager
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def test_secret_manager():
    # Get configuration from environment variables
    secret_server_url = os.getenv('SECRET_SERVER_URL', 'https://creds.gianteagle.com/SecretServer')
    secret_id = int(os.getenv('SECRET_ID_AZURE_CREDENTIALS', '42813'))
    
    logger.info(f"Testing Secret Manager with:")
    logger.info(f"Secret Server URL: {secret_server_url}")
    logger.info(f"Secret ID: {secret_id}")
    
    try:
        # Initialize SecretManager
        secret_manager = SecretManager(secret_server_url, secret_id)
        logger.info("SecretManager initialized successfully")
        
        # Test getting Azure credentials
        logger.info("Testing Azure credentials retrieval...")
        credentials = secret_manager.get_azure_credentials()
        logger.info("Successfully retrieved Azure credentials:")
        logger.info(f"Client ID: {credentials['client_id']}")
        logger.info(f"Tenant ID: {credentials['tenant_id']}")
        logger.info("Client Secret: [REDACTED]")
        
        # Test getting access token
        logger.info("Testing access token retrieval...")
        access_token = secret_manager.get_access_token()
        logger.info("Successfully obtained access token")
        logger.info(f"Token (first 10 chars): {access_token[:10]}...")
        
        return True
        
    except Exception as e:
        logger.error(f"Test failed: {str(e)}")
        return False

if __name__ == "__main__":
    success = test_secret_manager()
    if success:
        logger.info("All tests passed successfully!")
    else:
        logger.error("Tests failed!") 