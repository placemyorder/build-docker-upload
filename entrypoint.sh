#!/bin/bash

# Function to display usage information
usage() {
    echo "Usage: $0 -s <serviceName> -u <unittestpath> -b <buildNumber> -e <ecsRepoUrl>"
    exit 1
}

# Check if Docker is installed
if ! command -v docker &> /dev/null
then
    echo "Docker is not installed. Please install Docker to proceed."
    exit 1
fi

# Check if aws cli is installed
if ! command -v aws &> /dev/null
then
    echo "AWS Cli is not installed. Please install AWS Cli to proceed."
    exit 1
fi


# Parse parameters
while getopts "s:u:b:e:" opt; do
    case "$opt" in
        s) serviceName="$OPTARG" ;;
        u) unittestpath="$OPTARG" ;;
        b) buildNumber="$OPTARG" ;;
        e) ecsRepoUrl="$OPTARG" ;;
        *) usage ;;
    esac
done

# Check if all mandatory parameters are provided
if [ -z "$serviceName" ] || [ -z "$unittestpath" ] || [ -z "$buildNumber" ] || [ -z "$ecsRepoUrl" ]; then
    usage
fi

# Execute unit tests
dotnet restore --configfile ./Nuget.config
dotnet test "$unittestpath" /p:CollectCoverage=true /p:Threshold=80

# Exit if unit tests fail
if [ $? -ne 0 ]; then
    exit 1
fi

# Build Docker image
buildTag="${serviceName}:${buildNumber}"
docker build . -t "$buildTag"

# Log in to AWS ECR
echo "Logging into AWS ECR $ecsRepoUrl"
aws ecr get-login-password | docker login --username AWS --password-stdin "$ecsRepoUrl"

# Tag and push the Docker image to ECR
repoTag="${ecsRepoUrl}:${serviceName}_${buildNumber}"
docker tag "$buildTag" "$repoTag"
docker push "$repoTag"