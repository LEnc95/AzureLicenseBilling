# ---------------------------------------------------------
# Azure License Tracker Setup Script
# ---------------------------------------------------------

# Configuration
$VirtualEnvPath = "venv"

# ---------------------------------------------------------
# 1. Create and activate virtual environment if it doesn't exist
# ---------------------------------------------------------
Write-Host "Setting up Python virtual environment..."
if (-not (Test-Path $VirtualEnvPath)) {
    python -m venv $VirtualEnvPath
}

# Activate the virtual environment
& "$VirtualEnvPath\Scripts\Activate.ps1"

# ---------------------------------------------------------
# 2. Upgrade pip
# ---------------------------------------------------------
Write-Host "Upgrading pip..."
python -m pip install --upgrade pip

# ---------------------------------------------------------
# 3. Install required packages
# ---------------------------------------------------------
Write-Host "Installing required packages..."
pip install flask==2.0.1
pip install flask-azure-oauth==0.1.0
pip install python-dotenv==0.19.0
pip install gunicorn==20.1.0
pip install requests==2.31.0
pip install wfastcgi

# ---------------------------------------------------------
# 4. Verify installations
# ---------------------------------------------------------
Write-Host "`nVerifying installations..."
$packages = @(
    "flask",
    "flask_azure_oauth",
    "python-dotenv",
    "gunicorn",
    "requests",
    "wfastcgi"
)

foreach ($package in $packages) {
    $installed = python -c "import $package; print('$package is installed')" 2>$null
    if ($installed) {
        Write-Host "✓ $package is installed"
    } else {
        Write-Host "✗ $package is NOT installed"
    }
}

Write-Host "`nSetup completed!"
Write-Host "To activate the virtual environment, run:"
Write-Host '.\venv\Scripts\Activate.ps1' 