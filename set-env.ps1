# set_env.ps1

# Display options to the user
Write-Host "Please choose the environment:"
Write-Host "1. nonprod"
Write-Host "2. sandbox"
Write-Host "3. prod"

# Capture user input
$choice = Read-Host "Enter the number corresponding to your environment"

# Set environment variables based on the user's choice
switch ($choice) {
    1 {
        # For nonprod env.
        $env:ARM_CLIENT_ID = "nonprod-client-id"
        $env:ARM_CLIENT_SECRET = "nonprod-client-secret"
        $env:ARM_SUBSCRIPTION_ID = "nonprod-subscription-id"
        $env:ARM_TENANT_ID = "nonprod-tenant-id"
        Write-Host "Environment variables set for NONPROD"
    }
    2 {
        # For sandbox env.
        $env:ARM_CLIENT_ID = "sandbox-client-id"
        $env:ARM_CLIENT_SECRET = "sandbox-client-secret"
        $env:ARM_SUBSCRIPTION_ID = "sandbox-subscription-id"
        $env:ARM_TENANT_ID = "sandbox-tenant-id"
        Write-Host "Environment variables set for SANDBOX"
    }
    3 {
        # For prod env.
        $env:ARM_CLIENT_ID = "prod-client-id"
        $env:ARM_CLIENT_SECRET = "prod-client-secret"
        $env:ARM_SUBSCRIPTION_ID = "prod-subscription-id"
        $env:ARM_TENANT_ID = "prod-tenant-id"
        Write-Host "Environment variables set for PROD"
    }
    default {
        Write-Host "Invalid choice. Please select 1, 2, or 3."
        exit 1
    }
}

# Optionally, print the environment variables for verification
Write-Host "ARM_CLIENT_ID: $env:ARM_CLIENT_ID"
Write-Host "ARM_CLIENT_SECRET: $env:ARM_CLIENT_SECRET"
Write-Host "ARM_SUBSCRIPTION_ID: $env:ARM_SUBSCRIPTION_ID"
Write-Host "ARM_TENANT_ID: $env:ARM_TENANT_ID"



# Making the Script Accessible from Any Location ()
# Place the script in a folder (e.g., C:\scripts).

# Add the folder to the PATH environment variable so you can run it from anywhere on your system:

# Open Environment Variables via the Start menu.
# Under User variables, find Path, click Edit, and add C:\scripts.
# In System Properties, click Environment Variables.
# Click OK and restart any open command prompts to apply the changes.
# Now you can run the script from any location:
# set_env.ps1