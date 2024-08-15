#!/bin/bash

# Function to display usage information
usage() {
    echo "Usage: $0 -s <serviceName> -u <unittestpath> -b <buildNumber> -e <ecsRepoUrl> [-t <true|false>] [-d <dockerfileName>]"
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
    echo "AWS CLI is not installed. Please install AWS CLI to proceed."
    exit 1
fi

# Parse parameters
runTests="false"
dockerfileName=""
while getopts "s:u:b:e:t:d:" opt; do
    case "$opt" in
        s) serviceName="$OPTARG" ;;
        u) unittestpath="$OPTARG" ;;
        b) buildNumber="$OPTARG" ;;
        e) ecsRepoUrl="$OPTARG" ;;
        t) runTests="$OPTARG" ;;  # Optional flag to determine if unit tests should be run
        d) dockerfileName="$OPTARG" ;;  # Optional Dockerfile name
        *) usage ;;
    esac
done

# Check if all mandatory parameters are provided
if [ -z "$serviceName" ] || [ -z "$unittestpath" ] || [ -z "$buildNumber" ] || [ -z "$ecsRepoUrl" ]; then
    usage
fi

dotnet restore --configfile ./Nuget.config
# Execute unit tests if the flag is set to true
if [ "$runTests" == "true" ]; then
    dotnet test "$unittestpath" /p:CollectCoverage=true /p:Threshold=80

    # Exit if unit tests fail
    if [ $? -ne 0 ]; then
        exit 1
    fi
fi

# Build Docker image with optional Dockerfile
buildTag="${serviceName}:${buildNumber}"
if [ -n "$dockerfileName" ]; then
    docker build -f "$dockerfileName" . -t "$buildTag"
else
    docker build . -t "$buildTag"
fi

# Log in to AWS ECR
echo "Logging into AWS ECR $ecsRepoUrl"
aws ecr get-login-password | docker login --username AWS --password-stdin "$ecsRepoUrl"

# Tag and push the Docker image to ECR
repoTag="${ecsRepoUrl}:${serviceName}_${buildNumber}"
docker tag "$buildTag" "$repoTag"
docker push "$repoTag"
