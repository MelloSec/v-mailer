param(
    # Define all parameters that might be used
    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [string]$BUCKET,

    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [string]$BUCKETKEY,

    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [string]$BUCKETREGION,

    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [string]$BUCKETENDPOINT,

    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [string]$VMNAME,

    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [string]$AZREGION,

    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [string]$VAULTNAME,

    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [string]$VAULTGROUP,

    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [string]$SCRIPTURL,

    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [string]$DOMAINNAME,

    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [string]$DOMAINSUFFIX,

    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [switch]$genKeyVault,

    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [switch]$approve,

    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [switch]$rdp,

    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [bool]$s3enabled = $true

)

# Define a helper function to run each script
function Run-ScriptWithParams {
    param($ScriptPath, $Params)
    & $ScriptPath @Params
}

# Prepare parameter sets for each script
$ParamsKeyVault = @{
    VAULTNAME = $VAULTNAME
    VAULTGROUP = $VAULTGROUP

}


$ParamsBackend = @{
    BUCKET = $BUCKET
    BUCKETKEY = $BUCKETKEY
    BUCKETREGION = $BUCKETREGION
    BUCKETENDPOINT = $BUCKETENDPOINT
}

$ParamsMain = @{
    VMNAME = $VMNAME
    AZREGION = $AZREGION
    DOMAINNAME = $DOMAINNAME
    DOMAINSUFFIX = $DOMAINSUFFIX
}

$ParamsProviders = @{
    VAULTNAME = $VAULTNAME
    VAULTGROUP = $VAULTGROUP
}

$ParamsVariables = @{
    SCRIPTURL = $SCRIPTURL
}

# Check and create .\Deploy directory if it doesn't exist
$deployPath = ".\Deploy"
if(Test-Path $deployPath) { Remove-Item $deployPath -Recurse -Force}
# Remove-Item $deployPath\* -Recurse -Force

if (-not (Test-Path -Path $deployPath)) {
    New-Item -ItemType Directory -Path $deployPath -Force
}


if ($genKeyVault)
{ Run-ScriptWithParams ".\Gen-KeyVault.ps1" $ParamsKeyVault }

if ($s3enabled)
{
    Run-ScriptWithParams ".\Gen-Backend.ps1" $ParamsBackend
}
Run-ScriptWithParams ".\Gen-Main.ps1" $ParamsMain
Run-ScriptWithParams ".\Gen-Providers.ps1" $ParamsProviders
Run-ScriptWithParams ".\Gen-Variables.ps1" $ParamsVariables

# Change directory to .\Deploy and run terraform init
Set-Location -Path .\Deploy


if ($s3enabled){
$AWS_ACCESS_KEY_ID = Read-Host "Enter DigitalOcean S3 Key ID" -AsSecureString

$AWS_SECRET_ACCESS_KEY = Read-Host "Enter DigitalOcean S3 Secret Access Key" -AsSecureString

# Convert SecureString to Plain Text (for temporary use)
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($AWS_ACCESS_KEY_ID)
$PlainAWS_ACCESS_KEY_ID = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($AWS_SECRET_ACCESS_KEY)
$PlainAWS_SECRET_ACCESS_KEY = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

# Configure AWS CLI
aws configure set aws_access_key_id $PlainAWS_ACCESS_KEY_ID --profile digitalocean
aws configure set aws_secret_access_key $PlainAWS_SECRET_ACCESS_KEY --profile digitalocean
aws configure set default.region us-east-1 --profile digitalocean

$env:AWS_PROFILE="digitalocean"
# export AWS_PROFILE=digitalocean

# Initialize and copy tf to backend
# terraform init -migrate-state
# terraform init -reconfigure
terraform init -force-copy
terraform plan

if($approve){
    terraform apply --auto-approve
}else{
    terraform apply
}

if($rdp){
    mstsc /v:$VMNAME.$DOMAINNAME.$DOMAINSUFFIX /f
}


$vm = "$VMNAME"+"-vm"
$rg = "$VMNAME"+"-resources"

Write-Output "Invoking 'Invoke-WebRequest -Uri https://raw.githubusercontent.com/MelloSec/RepeatOffender/main/Choco.ps1 -OutFile Choco.ps1; .\Choco.ps1'"
az vm run-command invoke --command-id RunPowerShellScript --name $vm --resource-group $rg --scripts "Invoke-WebRequest -Uri https://raw.githubusercontent.com/MelloSec/RepeatOffender/main/Choco.ps1 -OutFile Choco.ps1; .\Choco.ps1"

Write-Output "Invoking 'Copy-Item "C:\ProgramData\chocolatey\choco.exe" "C:\Windows\System32"' -Force"
az vm run-command invoke --command-id RunPowerShellScript --name $vm --resource-group $rg --scripts "'C:\ProgramData\chocolatey\choco.exe' 'C:\Windows\System32' -Force"

Write-Output "Invoking 'Invoke-WebRequest -Uri https://raw.githubusercontent.com/MelloSec/RepeatOffender/main/Azure.ps1 -OutFile Azure.ps1; .\Azure.ps1'"
az vm run-command invoke --command-id RunPowerShellScript  --name $vm --resource-group $rg --scripts "Invoke-WebRequest -Uri https://raw.githubusercontent.com/MelloSec/RepeatOffender/main/Azure.ps1 -OutFile Azure.ps1; .\Azure.ps1"
}

# Write-Output "Invoking 'Invoke-WebRequest -Uri https://raw.githubusercontent.com/MelloSec/RepeatOffender/main/CloudBig.ps1 -OutFile CloudBig.ps1; .\CloudBig.ps1'"
# az vm run-command invoke --command-id RunPowerShellScript  --name $vm --resource-group $rg --scripts "Invoke-WebRequest -Uri https://raw.githubusercontent.com/MelloSec/RepeatOffender/main/CloudBig.ps1 -OutFile CloudBig.ps1; .\CloudBig.ps1"
# }
else {
    terraform init -reconfigure
    terraform plan
    terraform apply
}

# Usage
# .\Deploy.ps1 -BUCKET "myBucket" -BUCKETKEY "myBucketKey" -BUCKETREGION "us-east-1" -BUCKETENDPOINT "nyc" -VMNAME "myVmName" -AZREGION "east-us" -VAULTNAME "myVaultName" -VAULTGROUP "myVaultGroup" -SCRIPTURL "https://example.com/script.ps1"
