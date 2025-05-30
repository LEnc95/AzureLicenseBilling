# Generate a secure Flask secret key using .NET's RNGCryptoServiceProvider
$bytes = New-Object Byte[] 32
$rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
$rng.GetBytes($bytes)
$secretKey = [BitConverter]::ToString($bytes).Replace('-', '').ToLower()

# Set environment variables
$env:SECRET_KEY = $secretKey
$env:SECRET_SERVER_URL = "https://creds.gianteagle.com/SecretServer"
$env:SECRET_ID_AZURE_CREDENTIALS = "42813"
$env:REQUIRED_SECURITY_GROUP_ID = "0170f009-3f93-42aa-a860-5f8af82e90ba"  # Replace with your actual security group ID

Write-Host "Environment variables set successfully:"
Write-Host "SECRET_KEY: $secretKey"
Write-Host "SECRET_SERVER_URL: $env:SECRET_SERVER_URL"
Write-Host "SECRET_ID_AZURE_CREDENTIALS: $env:SECRET_ID_AZURE_CREDENTIALS"
Write-Host "REQUIRED_SECURITY_GROUP_ID: $env:REQUIRED_SECURITY_GROUP_ID"
Write-Host "Using Windows authentication (current user's credentials)" 