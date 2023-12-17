param(
    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [string]$SCRIPTURL
)

# Set default SCRIPTURL if not provided
if (-not $SCRIPTURL) {
    $SCRIPTURL = "https://github.com/mellosec/repeatoffender/Cloud.ps1"
}

# Check and create .\Deploy directory if it doesn't exist
$deployPath = ".\Deploy"
if (-not (Test-Path -Path $deployPath)) {
    New-Item -ItemType Directory -Path $deployPath
}

# Copy variables.tf template to .\Deploy
$templatePath = ".\templates\variables.tf"
$deployFilePath = Join-Path $deployPath "variables.tf"
Copy-Item -Path $templatePath -Destination $deployFilePath -Force

# Function to replace placeholder in file
function Replace-PlaceholderInFile {
    param($filePath, $placeholder, $value)
    (Get-Content $filePath) -replace "<<<$placeholder>>>", $value | Set-Content $filePath
}

# Replace placeholder with parameter value
Replace-PlaceholderInFile -filePath $deployFilePath -placeholder "SCRIPTURL" -value $SCRIPTURL


# Pipeline Usage
# Example 1: Using default SCRIPTURL
#.\Gen-Variables.ps1

## Example 2: Providing a custom SCRIPTURL
#$params = @{ SCRIPTURL = "https://custom-url.com/script.ps1" }
#$params | .\Gen-Variables.ps1
