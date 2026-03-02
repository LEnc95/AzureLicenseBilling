# Scripts Directory

> **Note:** All usage examples below assume you are running commands from the project root. Prefix all script calls with `scripts\` as shown.

This directory contains all the automation scripts for the Azure License Billing project, organized by purpose.

## Directory Structure

### deployment/
Contains scripts related to deploying the application:
- `deploy.ps1` - Main deployment script for Windows/IIS
  - Handles both development and production deployments
  - Configures IIS, Python environment, and application settings
  - Requires administrator privileges
- `deploy-config.json` - Deployment configuration file
  - Contains all configurable settings for deployment
  - Includes environment-specific configurations
  - Defines paths and application settings
- `deploy-flask-iis.ps1` - Legacy IIS deployment script
- `deploy.sh` - Linux deployment script

### data/
Contains scripts for data operations:
- `fetchData.ps1` - Fetches Azure license data
  - Retrieves license information from Azure
  - Updates local data store
- `fetchCreds.ps1` - Retrieves credentials from Secret Server
  - Manages authentication credentials
  - Updates local credential store
- `migrateToJson.ps1` - Data migration script
  - Converts data to JSON format
  - Handles data structure updates

### reports/
Contains scripts for generating reports:
- `graphReport.ps1` - Generates Graph API reports
  - Creates detailed license usage reports
  - Exports data in various formats
- `SPgraphReport.ps1` - Generates SharePoint Graph reports
  - Integrates with SharePoint
  - Creates team-specific reports
- `report.ps1` - General reporting script
  - Handles basic reporting tasks
  - Supports multiple output formats

### setup/
Contains scripts for environment setup:
- `setup.ps1` - Initial environment setup
  - Installs required dependencies
  - Configures Python environment
- `set_env.ps1` - Environment variable configuration
  - Sets up application environment
  - Manages configuration variables
- `graphAuth.ps1` - Graph API authentication setup
  - Configures Microsoft Graph API access
  - Manages authentication tokens

## Usage

### Deployment
```powershell
# For production deployment
.\scripts\deployment\deploy.ps1 -Environment production

# For development deployment
.\scripts\deployment\deploy.ps1 -Environment development

# Using custom configuration
.\scripts\deployment\deploy.ps1 -Environment production -ConfigPath "custom-config.json"
```

### Data Operations
```powershell
# Fetch Azure license data
.\scripts\data\fetchData.ps1

# Update credentials
.\scripts\data\fetchCreds.ps1

# Migrate data to JSON format
.\scripts\data\migrateToJson.ps1
```

### Reports
```powershell
# Generate Graph API report
.\scripts\reports\graphReport.ps1

# Generate SharePoint report
.\scripts\reports\SPgraphReport.ps1

# Generate general report
.\scripts\reports\report.ps1
```

### Setup
```powershell
# Initial setup
.\scripts\setup\setup.ps1

# Configure environment
.\scripts\setup\set_env.ps1

# Set up Graph API authentication
.\scripts\setup\graphAuth.ps1
```

## Configuration

The deployment configuration is stored in `scripts/deployment/deploy-config.json`. This file contains all the necessary settings for deployment, including:
- Application settings
  - Name, port, hostname
  - Python version
  - Virtual environment path
- IIS configuration
  - Application pool settings
  - Website settings
  - Physical path
- Secret server settings
  - Server URL
  - Secret ID
- Environment-specific settings
  - Development configuration
  - Production configuration
- Path configurations
  - Script directories
  - Project directories
  - Static and template paths

## Script Dependencies

Each script may have specific dependencies:
- Python 3.9 or later
- PowerShell 5.1 or later
- IIS with CGI module
- Access to Secret Server
- Microsoft Graph API access
- SharePoint access (for SP reports)

## Best Practices

1. **Script Execution**
   - Always run scripts from the project root directory
   - Use appropriate environment parameters
   - Check prerequisites before running

2. **Configuration**
   - Keep sensitive data in Secret Server
   - Use environment-specific configurations
   - Document any custom configurations

3. **Maintenance**
   - Keep scripts up to date
   - Document changes
   - Test in development before production

4. **Security**
   - Use appropriate permissions
   - Follow least privilege principle
   - Secure sensitive data

## Troubleshooting

Common issues and solutions:
1. **Permission Issues**
   - Run as administrator
   - Check IIS_IUSRS permissions
   - Verify file access rights

2. **Configuration Problems**
   - Verify config.json format
   - Check environment variables
   - Validate paths

3. **Deployment Failures**
   - Check IIS configuration
   - Verify Python installation
   - Review application logs

## Notes

- All scripts should be run from the project root directory
- Most scripts require administrator privileges
- Make sure to update the configuration file before deployment
- Keep the scripts directory in version control
- Document any custom modifications
- Test changes in development first 