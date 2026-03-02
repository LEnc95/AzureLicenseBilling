# ---------------------------------------------------------
# Azure License Tracker Deployment Script
# ---------------------------------------------------------
# This script handles the deployment of the Azure License Tracker application
# to IIS on Windows. It supports both development and production environments.
#
# Usage:
#   .\deploy.ps1 -Environment production
#   .\deploy.ps1 -Environment development
#
# Requirements:
#   - Administrator privileges
#   - Python 3.9 or later
#   - IIS with CGI module installed
#   - Access to Secret Server
# ---------------------------------------------------------

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('development', 'production')]
    [string]$Environment = 'production',
    
    [Parameter(Mandatory=$false)]
    [string]$ConfigPath = 'deploy-config.json'
)

# ---------------------------------------------------------
# Helper Functions
# ---------------------------------------------------------
function Get-SecretServerSecretDetails {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [int]$SecretID,
        [Parameter(Mandatory=$false)]
        [string]$SecretServerName = 'creds.gianteagle.com',
        [switch]$TLS12
    )

    if ($TLS12) {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    }

    $BaseURL = "https://$SecretServerName/SecretServer/winauthwebservices/api/v1/secrets"
    $Arglist = @{
        Uri = "$BaseURL/$SecretID"
        UseDefaultCredentials = $true
    }

    Write-Verbose "Retrieving secret details from: $($Arglist['Uri'])"
    $SecretDetails = Invoke-RestMethod @Arglist
    return $SecretDetails
}

function Test-Administrator {
    $user = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal $user
    return $principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

function Get-ScriptDirectory {
    $Invocation = (Get-Variable MyInvocation -Scope 1).Value
    Split-Path $Invocation.MyCommand.Path
}

# ---------------------------------------------------------
# 1. Load Configuration
# ---------------------------------------------------------
Write-Host "Loading deployment configuration..."
$scriptDir = Get-ScriptDirectory
$configPath = Join-Path $scriptDir $ConfigPath

if (-not (Test-Path $configPath)) {
    throw "Configuration file not found at: $configPath"
}

$config = Get-Content $configPath | ConvertFrom-Json
$envConfig = $config.environment.$Environment

# ---------------------------------------------------------
# 2. Check Prerequisites
# ---------------------------------------------------------
Write-Host "Checking prerequisites..."
if (-not (Test-Administrator)) {
    throw "This script must be run as Administrator"
}

# Check Python installation
$pythonVersion = python --version
if (-not $pythonVersion) {
    throw "Python is not installed or not in PATH"
}

# ---------------------------------------------------------
# 3. Install IIS and Required Features
# ---------------------------------------------------------
Write-Host "Installing IIS and required features..."
Import-Module ServerManager
Add-WindowsFeature Web-Server, Web-CGI

# ---------------------------------------------------------
# 4. Set up Python Environment
# ---------------------------------------------------------
Write-Host "Setting up Python environment..."
$projectRoot = Join-Path $scriptDir $config.paths.project.root
$venvPath = Join-Path $projectRoot $config.app.virtual_env_path

if (-not (Test-Path $venvPath)) {
    python -m venv $venvPath
}
& "$venvPath\Scripts\Activate.ps1"

# Install dependencies
$requirementsPath = Join-Path $projectRoot "requirements.txt"
pip install -r $requirementsPath
pip install wfastcgi
wfastcgi-enable

# ---------------------------------------------------------
# 5. Configure IIS
# ---------------------------------------------------------
Write-Host "Configuring IIS..."
Import-Module WebAdministration

# Create Application Pool
$appPoolName = $config.iis.app_pool.name
if (-not (Test-Path "IIS:\AppPools\$appPoolName")) {
    New-WebAppPool -Name $appPoolName
    Set-ItemProperty "IIS:\AppPools\$appPoolName" -Name managedRuntimeVersion -Value $config.iis.app_pool.managed_runtime_version
    Set-ItemProperty "IIS:\AppPools\$appPoolName" -Name managedPipelineMode -Value $config.iis.app_pool.managed_pipeline_mode
}

# Create Website
$siteName = $config.iis.site.name
$sitePath = $config.iis.site.physical_path
$port = $config.app.port
$hostname = $envConfig.host

if (-not (Test-Path "IIS:\Sites\$siteName")) {
    New-Website -Name $siteName -PhysicalPath $sitePath -ApplicationPool $appPoolName -Port $port -HostHeader $hostname
} else {
    # Update existing website binding
    $site = Get-Item "IIS:\Sites\$siteName"
    $binding = $site.Bindings.Collection | Where-Object { $_.bindingInformation -like "*:$port:*" }
    if ($binding) {
        $binding.bindingInformation = "*:${port}:${hostname}"
    } else {
        New-WebBinding -Name $siteName -Protocol "http" -Port $port -HostHeader $hostname
    }
}

# ---------------------------------------------------------
# 6. Set up Environment Variables
# ---------------------------------------------------------
Write-Host "Setting up environment variables..."
$envContent = @"
SECRET_SERVER_URL=$($config.secrets.server_url)
SECRET_SERVER_ID=$($config.secrets.secret_id)
FLASK_SECRET_KEY=$(New-Guid)
FLASK_ENV=$Environment
FLASK_DEBUG=$($envConfig.debug)
"@

$envPath = Join-Path $projectRoot ".env"
$envContent | Out-File -FilePath $envPath -Encoding UTF8

# ---------------------------------------------------------
# 7. Create web.config
# ---------------------------------------------------------
Write-Host "Creating web.config..."
$pythonPath = (Get-Command python).Path
$wfastcgiPath = (Get-Command wfastcgi).Path

$webConfig = @"
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <system.webServer>
    <handlers>
      <add name="PythonHandler" path="*" verb="*" modules="FastCgiModule" scriptProcessor="$pythonPath|$wfastcgiPath" resourceType="Unspecified" requireAccess="Script" />
    </handlers>
    <rewrite>
      <rules>
        <rule name="Static Files" stopProcessing="true">
          <match url="^/static/.*" ignoreCase="true" />
          <action type="Rewrite" url="{R:0}" />
        </rule>
        <rule name="Configure Python" stopProcessing="true">
          <match url="(.*)" ignoreCase="false" />
          <action type="Rewrite" url="handler.fcgi/{R:1}" appendQueryString="true" />
        </rule>
      </rules>
    </rewrite>
  </system.webServer>
</configuration>
"@
$webConfigPath = Join-Path $projectRoot "web.config"
$webConfig | Out-File -FilePath $webConfigPath -Encoding UTF8

# ---------------------------------------------------------
# 8. Set Permissions
# ---------------------------------------------------------
Write-Host "Setting directory permissions..."
$acl = Get-Acl $sitePath
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule("IIS_IUSRS","ReadAndExecute","ContainerInherit,ObjectInherit","None","Allow")
$acl.SetAccessRule($rule)
Set-Acl $sitePath $acl

# ---------------------------------------------------------
# 9. Completion
# ---------------------------------------------------------
Write-Host "`nDeployment completed successfully!"
Write-Host "The application is now accessible at: http://${hostname}:${port}"
Write-Host "`nNote: Make sure to restart the IIS website if it was already running."
Write-Host "Also ensure that '${hostname}' is added to your hosts file or DNS." 