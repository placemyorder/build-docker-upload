param(
    [parameter(Mandatory=$true)]
    [String]$serviceName,
    [parameter(Mandatory=$true)]
    [String]$unittestpath,
    [parameter(Mandatory=$true)]
    [String]$infraterraformDir,
    [parameter(Mandatory=$true)]
    [String]$buildNumber,
    [parameter(Mandatory=$true)]
    [String]$ecsRepoUrl
)

Set-Location $infraterraformDir

#Execute unit tests first
dotnet restore --configfile ./Nuget.config
dotnet test $unittestpath /p:CollectCoverage=true /p:Threshold=80

#disable for first run
if($LASTEXITCODE -ne 0)
{
    exit 1
}

$buildTag = $serviceName + ":$buildNumber"

docker build . -t $buildTag

Write-Host -foreground green "Login into AWS ECR  $ecsRepoUrl"
aws ecr get-login-password | docker login --username AWS --password-stdin $ecsRepoUrl

$RepoTag = $ecsRepoUrl + ":$serviceName" + "_" + $buildNumber


docker tag $buildTag $RepoTag

docker push $RepoTag


