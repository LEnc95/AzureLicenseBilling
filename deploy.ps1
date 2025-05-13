# ---------------------------------------------------------
# Azure License Tracker Deployment Script
# ---------------------------------------------------------

# Function to retrieve secrets from Secret Server
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

# ---------------------------------------------------------
# Configuration
# ---------------------------------------------------------
$SecretID = 42813  # Your Secret Server ID
$AppName = "AzureLicenseTracker"
$PythonVersion = "3.9"
$VirtualEnvPath = "venv"
$HostName = "MSbilling"
$Port = 8080

# ---------------------------------------------------------
# 1. Retrieve credentials from Secret Server
# ---------------------------------------------------------
Write-Host "Retrieving credentials from Secret Server..."
$secretDetails = Get-SecretServerSecretDetails -SecretID $SecretID -TLS12

# Extract secrets
$clientId = ($secretDetails.items | Where-Object { $_.slug -eq "clientId" }).itemValue
$clientSecret = ($secretDetails.items | Where-Object { $_.slug -eq "clientSecret" }).itemValue
$tenantId = ($secretDetails.items | Where-Object { $_.slug -eq "tenantId" }).itemValue
$allowedGroupId = ($secretDetails.items | Where-Object { $_.slug -eq "allowedGroupId" }).itemValue

# ---------------------------------------------------------
# 2. Create and activate virtual environment
# ---------------------------------------------------------
Write-Host "Setting up Python virtual environment..."
if (-not (Test-Path $VirtualEnvPath)) {
    python -m venv $VirtualEnvPath
}
& "$VirtualEnvPath\Scripts\Activate.ps1"

# ---------------------------------------------------------
# 3. Install dependencies
# ---------------------------------------------------------
Write-Host "Installing Python dependencies..."
pip install -r requirements.txt

# ---------------------------------------------------------
# 4. Create .env file
# ---------------------------------------------------------
Write-Host "Creating environment configuration..."
$envContent = @"
SECRET_SERVER_URL=https://creds.gianteagle.com/SecretServer
SECRET_SERVER_ID=$SecretID
FLASK_SECRET_KEY=$(New-Guid)
"@

$envContent | Out-File -FilePath ".env" -Encoding UTF8

# ---------------------------------------------------------
# 5. Create IIS Application Pool and Website
# ---------------------------------------------------------
Write-Host "Configuring IIS..."
Import-Module WebAdministration

# Create Application Pool
if (-not (Test-Path "IIS:\AppPools\$AppName")) {
    New-WebAppPool -Name $AppName
    Set-ItemProperty "IIS:\AppPools\$AppName" -Name managedRuntimeVersion -Value "v4.0"
    Set-ItemProperty "IIS:\AppPools\$AppName" -Name managedPipelineMode -Value 1
}

# Create Website
$sitePath = (Get-Location).Path
if (-not (Test-Path "IIS:\Sites\$AppName")) {
    New-Website -Name $AppName -PhysicalPath $sitePath -ApplicationPool $AppName -Port $Port -HostHeader $HostName
} else {
    # Update existing website binding
    $site = Get-Item "IIS:\Sites\$AppName"
    $binding = $site.Bindings.Collection | Where-Object { $_.bindingInformation -like "*:$Port:*" }
    if ($binding) {
        $binding.bindingInformation = "*:$Port`:$HostName"
    } else {
        New-WebBinding -Name $AppName -Protocol "http" -Port $Port -HostHeader $HostName
    }
}

# ---------------------------------------------------------
# 6. Install and configure wfastcgi
# ---------------------------------------------------------
Write-Host "Configuring FastCGI..."
pip install wfastcgi
wfastcgi-enable

# ---------------------------------------------------------
# 7. Create web.config if it doesn't exist
# ---------------------------------------------------------
if (-not (Test-Path "web.config")) {
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
    $webConfig | Out-File -FilePath "web.config" -Encoding UTF8
}

Write-Host "`nDeployment completed successfully!"
Write-Host "The application is now accessible at: http://${HostName}:${Port}"
Write-Host "`nNote: Make sure to restart the IIS website if it was already running."
Write-Host "Also ensure that '${HostName}' is added to your hosts file or DNS." 