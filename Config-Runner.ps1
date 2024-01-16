# Define the path to the config.json file
$configFilePath = ".\config.json"

# Read the config.json file and convert it from JSON
if (Test-Path $configFilePath) {
    $configContent = Get-Content $configFilePath -Raw | ConvertFrom-Json
} else {
    Write-Error "Config file not found at path: $configFilePath"
    exit
}

# Prepare the parameters for splatting
$params = @{}

# Dynamically add each property from the config file to the params hashtable
foreach ($property in $configContent.PSObject.Properties) {
    $params[$property.Name] = $property.Value
}

# Run Gen-Sleepload.ps1 script with the parameters from the config file
.\Gen-Assload.ps1 @params
# Define the path to the config.json file
$configFilePath = ".\config.json"

# Read the config.json file and convert it from JSON
if (Test-Path $configFilePath) {
    $configContent = Get-Content $configFilePath -Raw | ConvertFrom-Json
} else {
    Write-Error "Config file not found at path: $configFilePath"
    exit
}

# Prepare the parameters for splatting
$params = @{}

# Dynamically add each property from the config file to the params hashtable
foreach ($property in $configContent.PSObject.Properties) {
    $params[$property.Name] = $property.Value
}

# Run Gen-Sleepload.ps1 script with the parameters from the config file
.\Gen-All.ps1 @params
