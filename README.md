# vMailer
Proof-of-Concept IaC deployment for phishing engagements

An Azure Win10 Office VM configured with powershell tools, Namecheap DNS records managed by Terraform and state stored in DigitalOcean Spaces S3.  

Deploy script creates your deployment from templates using values passed on the command line. Terraform state is stored remotely if $s3enabled = $true, and DNS records are provisioned and kept to update through this setup. Make changes to the terraform config and re-apply to update, change or delete records, redeploy the server, etc.

Pass your parameter set as a hashtable, make your changes to this and the values will be passed to the necesarry subscripts. Terraform will kick off automatically from the .\Deploy folder

## Quick Deploy - Generate a new keyvault, use a digitalocean S3 spaces backend, don't auto-approve the deployment before applying, automatically RDP after applying (beofre the scripts run)
```powershell
$params = @{
    genKeyVault = $true
    s3enabled = $true
    rdp = $true
    approve = $false
    BUCKET = "mrbucket"
    BUCKETKEY = "vmailer"
    BUCKETREGION = "us-east-1"
    BUCKETENDPOINT = "nyc3"
    VMNAME = "vmailer"
    AZREGION = "east-us"
    VAULTNAME = "vmailer"
    VAULTGROUP = "vmailer"
    DOMAINNAME = "phishery"
    DOMAINSUFFIX = "org"
}
.\Deploy.ps1 @params
```

Two scripts will run post-deployment using az vm run-command. One will install chocolatey (https://raw.githubusercontent.com/MelloSec/RepeatOffender/main/Choco.ps1) and the other a bunch of tools (https://raw.githubusercontent.com/MelloSec/RepeatOffender/main/CloudBig.ps1). Change the URLs in 'Deploy.ps1' if you want to run something else. 


## Purpose
 This will spin up a new Windows Office VM on Azure with an S3 backend (optional), create DNS records on namecheap, set an SPF record for your machine, open the NSG rules to your current IP and install a bunch of Azure pentesting tools with the default script extension. Not a cheap VM, Standard DS, but reasonable. You may want to adjust that in .\templates\main.tf. Gen-Keyvault (and the switch in Deploy.ps1) are currently shakey. Better to specify an existing Keyvault and group as arguments.

## Login using Azure CLI
```powershell
az login
```

## Optional - Create a KeyVault with Azure CLI, set Network rule for your current public IP
```powershell
.\Gen-KeyVault.ps1
```

## Set your parameters
```powershell
$bucket="BucketName"
$bucketKey="vmailer"
$bucketRegion="us-east-1"
$endpoint="nyc"
$vmName="vmailer"
$azregion="us-east-1"
$vaultName="CoolVault"
$vaultGroup="CoolVault_rg"
$domainname="attackersoft"
$domainsuffix="com"
$scriptUrl = "https://github.com/mellosec/repeatoffender/cloud.ps1"
```

## Generate New Templates and Deploy with the helper script, specify existing KeyVault, run Post-Deployment script to provision tools
```powershell
.\Deploy.ps1 -BUCKET $bucket -BUCKETKEY $bucketKey -BUCKETREGION $bucketRegion -BUCKETENDPOINT $endpoint -VMNAME $vmName -AZREGION $azregion -VAULTNAME $vaultName -VAULTGROUP $vaultUrl -SCRIPTURL $scriptUrl -DOMAINNAME $domain -DOMAINSUFFIX $domainsuffix
```

## Generate New Keyvault, New Templates, Deploy, set Network rule for your current public IP, run Post-Deployment script to provision tools
```powershell
.\Deploy.ps1 -BUCKET $bucket -BUCKETKEY $bucketKey -BUCKETREGION $bucketRegion -BUCKETENDPOINT $endpoint -VMNAME $vmName -AZREGION $azregion -VAULTNAME $vaultName -VAULTGROUP $vaultUrl -SCRIPTURL $scriptUrl -DOMAINNAME $domain -DOMAINSUFFIX $domainsuffix -genKeyVault
```

## S3 Backend Backend Template 
To use the deploy.ps1 helper script you need to create an S3 bucket on DigitalOcean Spaces. Heres an example so you can find your values. This is backend.tf and those are the parameters we use. Those are replaced by the templating script by what you pass as arguments. Create a bucket and find these:

```powershell
terraform {
  backend "s3" {
    bucket         = "$BUCKET"
    key            = "$BUCKETKEY\terraform.tfstate"
    region         = "$BUCKETREGION"
    endpoint       = "$BUCKETENDPOINT.digitaloceanspaces.com"  # Replace with the appropriate endpoint for your region
    # access_key = ""
    # secret_key = ""
    skip_credentials_validation = true
    skip_metadata_api_check = true    
  }
}
```

<!-- ### Deploy Manually with CLi using Secure Strings
```powershell
# Prompt for AWS Access Key ID and Secret Access Key
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

# Initialize and copy tf to backend, will prompt for VM password and username
terraform init -force-copy
terraform plan


# Clear Plain Text Variables from Memory
$choice = Read-Host "Enter 'Y' to clear plaintext creds from memory"
if($choice = 'Y'){
Remove-Variable -Name PlainAWS_ACCESS_KEY_ID, PlainAWS_SECRET_ACCESS_KEY
[System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
}
```

## Deploy the Dev way

```powershell
$AWS_ACCESS_KEY_ID = ""
$AWS_SECRET_ACCESS_KEY = ""

aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID --profile digitalocean
aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY --profile digitalocean
aws configure set default.region us-east-1 --profile digitalocean
# If needed, you can also set the output format
# aws configure set default.output json --profile digitalocean

# Set AWS_PROFILE environment variable
$env:AWS_PROFILE="digitalocean"
# export AWS_PROFILE=digitalocean

terraform init -force-copy
terraform plan
```

## Deploy the local way, no S3 (might work still?):
```powershell
mv backend.tf backend.nah
terraform init
terraform plan
terraform apply
```
 -->

