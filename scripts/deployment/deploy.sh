#!/bin/bash

# ---------------------------------------------------------
# Azure License Tracker Deployment Script (Linux)
# ---------------------------------------------------------

# Configuration
SECRET_ID=42813  # Your Secret Server ID
APP_NAME="AzureLicenseTracker"
PYTHON_VERSION="3.9"
VENV_PATH="venv"
HOST_NAME="MSbilling"
PORT=8080

# ---------------------------------------------------------
# 1. Create and activate virtual environment
# ---------------------------------------------------------
echo "Setting up Python virtual environment..."
if [ ! -d "$VENV_PATH" ]; then
    python3 -m venv $VENV_PATH
fi
source $VENV_PATH/bin/activate

# ---------------------------------------------------------
# 2. Install dependencies
# ---------------------------------------------------------
echo "Installing Python dependencies..."
pip install -r requirements.txt

# ---------------------------------------------------------
# 3. Create .env file
# ---------------------------------------------------------
echo "Creating environment configuration..."
cat > .env << EOL
SECRET_SERVER_URL=https://creds.gianteagle.com/SecretServer
SECRET_SERVER_ID=$SECRET_ID
FLASK_SECRET_KEY=$(python3 -c 'import uuid; print(uuid.uuid4())')
EOL

# ---------------------------------------------------------
# 4. Create systemd service file
# ---------------------------------------------------------
echo "Creating systemd service..."
sudo tee /etc/systemd/system/$APP_NAME.service << EOL
[Unit]
Description=Azure License Tracker
After=network.target

[Service]
User=$USER
WorkingDirectory=$(pwd)
Environment="PATH=$(pwd)/$VENV_PATH/bin"
ExecStart=$(pwd)/$VENV_PATH/bin/gunicorn --workers 3 --bind $HOST_NAME:$PORT server:app
Restart=always

[Install]
WantedBy=multi-user.target
EOL

# ---------------------------------------------------------
# 5. Add hostname to /etc/hosts if not present
# ---------------------------------------------------------
if ! grep -q "$HOST_NAME" /etc/hosts; then
    echo "Adding $HOST_NAME to /etc/hosts..."
    echo "127.0.0.1 $HOST_NAME" | sudo tee -a /etc/hosts
fi

# ---------------------------------------------------------
# 6. Enable and start the service
# ---------------------------------------------------------
echo "Enabling and starting service..."
sudo systemctl daemon-reload
sudo systemctl enable $APP_NAME
sudo systemctl start $APP_NAME

echo -e "\nDeployment completed successfully!"
echo "The application is now accessible at: http://$HOST_NAME:$PORT"
echo -e "\nTo check the service status, run: sudo systemctl status $APP_NAME"
echo "To view logs, run: sudo journalctl -u $APP_NAME -f" 