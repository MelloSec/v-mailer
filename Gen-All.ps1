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


# if ($genKeyVault)
# { Run-ScriptWithParams ".\Gen-KeyVault.ps1" $ParamsKeyVault }

if ($s3enabled)
{
    Run-ScriptWithParams ".\Gen-Backend.ps1" $ParamsBackend
}
Run-ScriptWithParams ".\Gen-Main.ps1" $ParamsMain
Run-ScriptWithParams ".\Gen-Providers.ps1" $ParamsProviders
Run-ScriptWithParams ".\Gen-Variables.ps1" $ParamsVariables