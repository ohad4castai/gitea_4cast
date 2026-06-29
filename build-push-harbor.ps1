<#
.SYNOPSIS
Builds and pushes the Gitea Docker image to the Harbor registry.

.DESCRIPTION
This script builds the Gitea Docker image locally using the existing Dockerfile
and then pushes the generated image to your specified Harbor registry.

.EXAMPLE
.\build-push-harbor.ps1
#>

# Registry settings
$RegistryUrl = "harbor.4cast-it.com"
$ProjectName = "4cast-tools"
$ImageName = "gitea"
$Tag = "1.26.4"

$FullImageName = "${RegistryUrl}/${ProjectName}/${ImageName}:${Tag}"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " Building and Pushing 4Cast Git Server " -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Ensure Docker is running
Write-Host "Checking if Docker is running..."
docker info > $null 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Docker is not running. Attempting to start Docker Desktop..." -ForegroundColor Yellow
    Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"
    
    # Wait for Docker to start
    $retryCount = 0
    $maxRetries = 60
    while ($retryCount -lt $maxRetries) {
        Start-Sleep -Seconds 2
        docker info > $null 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "`nDocker has started successfully." -ForegroundColor Green
            break
        }
        $retryCount++
        Write-Host -NoNewline "."
    }
    Write-Host ""
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to start Docker Desktop or Docker engine didn't become responsive in time."
        exit 1
    }
} else {
    Write-Host "Docker is running." -ForegroundColor Green
}
Write-Host ""

# Authenticate with Harbor
Write-Host "Logging into Docker registry: $RegistryUrl..."
"oFqe9c1Lx" | docker login $RegistryUrl -u "devops" --password-stdin

if ($LASTEXITCODE -ne 0) {
    Write-Error "Docker login failed. Please check credentials."
    exit $LASTEXITCODE
}
Write-Host ""

# 1. Build the image
Write-Host "Building Docker image: $FullImageName" -ForegroundColor Green
docker build --build-arg GITEA_VERSION=$Tag -t $FullImageName .

if ($LASTEXITCODE -ne 0) {
    Write-Error "Docker build failed."
    exit $LASTEXITCODE
}

# 2. Push the image
Write-Host "Pushing Docker image to Harbor..." -ForegroundColor Green
docker push $FullImageName

if ($LASTEXITCODE -ne 0) {
    Write-Error "Docker push failed. Make sure you are logged in to $RegistryUrl."
    exit $LASTEXITCODE
}

Write-Host "Successfully built and pushed $FullImageName!" -ForegroundColor Green
