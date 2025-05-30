# Azure License Billing Tracker

A web application for tracking Azure AD license usage and billing information, with automated data collection and reporting capabilities.

## Overview

This application provides a web interface for monitoring Azure AD license usage, with features including:
- Real-time tracking of Azure AD license usage
- Visual representation of license consumption
- Windows Integrated Authentication with Secret Server
- Azure AD security group-based access control
- Automated data collection and reporting
- Integration with Microsoft Graph API

## Quick Start

1. Clone the repository:
```bash
git clone https://github.com/yourusername/AzureLicenseBilling.git
cd AzureLicenseBilling
```

2. Create and activate a virtual environment:
```bash
python -m venv .venv
.venv\Scripts\activate  # Windows
```

3. Install dependencies:
```bash
pip install -r requirements.txt
```

4. Create a `.env` file in the project root with the following variables:
```
# Flask secret key (generate a new one for production)
SECRET_KEY=your-flask-secret-key

# Secret Server configuration
SECRET_SERVER_URL=https://creds.gianteagle.com/SecretServer
SECRET_ID_AZURE_CREDENTIALS=42813

# Azure AD group for access control
ALLOWED_GROUP_ID=your-entra-group-id
```

5. Run the application:
```bash
python server.py
```

The application will be available at http://127.0.0.1:5000

## Project Structure

```
AzureLicenseBilling/
├── scripts/           # Automation and utility scripts
│   ├── data/         # Data collection scripts
│   ├── deployment/   # Deployment scripts
│   ├── reports/      # Reporting scripts
│   └── setup/        # Setup and configuration scripts
├── static/           # Static web assets
├── dat/             # Data storage
├── server.py        # Main application file
├── secret_manager.py # Secret Server integration
└── requirements.txt  # Python dependencies
```

## Authentication

This application uses Windows Integrated Authentication to connect to Secret Server. Make sure you're running the application with a user account that has access to the Secret Server.

## Automation Scripts

The project includes various automation scripts for data collection, reporting, and deployment. See the [scripts README](scripts/README.md) for detailed information about:
- Data collection and processing
- Report generation
- Deployment automation
- Environment setup
- Configuration management

## Development

- Backend: Flask (Python)
- Frontend: Vanilla JavaScript with Chart.js
- Authentication: Azure AD
- Data Storage: JSON files
- Automation: PowerShell scripts

## Security

- Windows Integrated Authentication for Secret Server access
- Azure AD security groups for access control
- Sensitive credentials stored in Secret Server
- Environment-based configuration

## License

[Your License Here] 