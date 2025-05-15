import os
from secret_manager import SecretManager
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def main():
    # Log environment variables (except secret key)
    logger.info("Environment variables:")
    logger.info(f"SECRET_SERVER_URL: {os.getenv('SECRET_SERVER_URL')}")
    logger.info(f"SECRET_ID_AZURE_CREDENTIALS: {os.getenv('SECRET_ID_AZURE_CREDENTIALS')}")
    logger.info(f"SECRET_SERVER_USERNAME: {os.getenv('SECRET_SERVER_USERNAME')}")
    
    try:
        # Initialize SecretManager
        secret_manager = SecretManager(
            os.getenv('SECRET_SERVER_URL'),
            int(os.getenv('SECRET_ID_AZURE_CREDENTIALS'))
        )
        
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
        
    except Exception as e:
        logger.error(f"Error: {str(e)}")
        raise

if __name__ == "__main__":
    main() 