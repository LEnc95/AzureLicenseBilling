# =========================
# Flask IIS Deployment Script
# =========================
# This script automates the deployment of a Flask app to IIS on Windows.
# It installs IIS, configures Python, sets up your app, and creates a site.
# Edit the variables below to match your environment.

# -------------------------
# CONFIGURATION
# -------------------------
# Path to your Flask app directory (where server.py and requirements.txt are)
$appDir = Join-Path $PSScriptRoot '..\..\..\..\inetpub\wwwroot\azlicense'
# Name for your IIS site
$siteName = "AzLicense"
# Port to run your site on (change if you want)
$port = 8080

# -------------------------
# 1. Install IIS and CGI Module
# -------------------------
Write-Host "Installing IIS and CGI module (if not already installed)..."
Import-Module ServerManager
Add-WindowsFeature Web-Server, Web-CGI

# -------------------------
# 2. Install Python dependencies
# -------------------------
Write-Host "Installing Python dependencies..."
# Make sure Python and pip are in your PATH
pip install -r "$appDir\requirements.txt"
pip install wfastcgi
python -m wfastcgi.enable

# -------------------------
# 3. Create web.config for IIS
# -------------------------
Write-Host "Creating web.config for IIS FastCGI integration..."
$pythonPath = (Get-Command python).Source
$wfastcgiPath = (Get-Command wfastcgi-enable).Source.Replace('-enable', '.py')

@"
<configuration>
  <system.webServer>
    <handlers>
      <add name="PythonHandler" path="*" verb="*" modules="FastCgiModule" scriptProcessor="$pythonPath|$wfastcgiPath" resourceType="Unspecified" requireAccess="Script" />
    </handlers>
    <defaultDocument>
      <files>
        <add value="index.html" />
      </files>
    </defaultDocument>
  </system.webServer>
  <appSettings>
    <add key="WSGI_HANDLER" value="server.app" />
    <!-- Add other environment variables here if needed, e.g.:
    <add key="SECRET_SERVER_URL" value="https://yourserver" />
    -->
  </appSettings>
</configuration>
"@ | Set-Content -Path "$appDir\web.config"

# -------------------------
# 4. Create IIS Site
# -------------------------
Write-Host "Creating IIS site..."
Import-Module WebAdministration
if (-not (Test-Path IIS:\Sites\$siteName)) {
    New-Item -Path IIS:\Sites\$siteName -PhysicalPath $appDir -BindingInformation "*:${port}:"
    Set-ItemProperty IIS:\Sites\$siteName -Name applicationPool -Value "DefaultAppPool"
    Write-Host "Site '$siteName' created on port $port."
} else {
    Write-Host "Site '$siteName' already exists. Skipping creation."
}

# -------------------------
# 5. Set Permissions
# -------------------------
Write-Host "Setting permissions for IIS_IUSRS on your app directory..."
$acl = Get-Acl $appDir
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule("IIS_IUSRS","ReadAndExecute","ContainerInherit,ObjectInherit","None","Allow")
$acl.SetAccessRule($rule)
Set-Acl $appDir $acl

# -------------------------
# 6. (Optional) Set System Environment Variables
# -------------------------
# Uncomment and edit the following lines if you want to set system-wide environment variables
# [System.Environment]::SetEnvironmentVariable('SECRET_SERVER_URL', 'https://yourserver', 'Machine')
# [System.Environment]::SetEnvironmentVariable('SECRET_ID_AZURE_CREDENTIALS', '42813', 'Machine')

# -------------------------
# 7. Done!
# -------------------------
Write-Host ""
Write-Host "==============================================="
Write-Host "Deployment complete!"
Write-Host "Browse to http://localhost:$port or http://<your-server>:$port"
Write-Host "If you need to change environment variables, edit web.config or set them in Windows."
Write-Host "Check IIS Manager if you need to troubleshoot."
Write-Host "==============================================="