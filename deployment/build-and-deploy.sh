#!/bin/bash

# Build, Push, and Deploy to Azure Container Apps
# This script builds Docker images, pushes them to Docker Hub, and deploys to Azure Container Apps

set -e  # Exit on any error

# Change to the script's directory
cd "$(dirname "$0")"

echo "Sourcing .env file..."
source .env

# Check if required tools are installed
echo "🔍 Checking prerequisites..."

if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker and try again."
    exit 1
fi

if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI is not installed. Please install Azure CLI and try again."
    exit 1
fi

if ! command -v diagrid &> /dev/null; then
    echo "❌ Diagrid CLI is not installed. Please install Diagrid CLI and try again."
    exit 1
fi

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker and try again."
    exit 1
fi

echo "✅ All prerequisites are available"

# Step 1: Build and Push Docker Images
echo ""
echo "🐳 Building and pushing Docker images to Docker Hub..."

# Login to Docker Hub
echo "🔐 Logging in to Docker Hub..."
docker login

# Build and push inventory service
echo "📦 Building inventory service for AMD64..."
docker buildx build \
    --platform linux/amd64 \
    --tag $INVENTORY_IMAGE:$TAG \
    --push \
    ../inventory-service

# Build and push order management service
echo "📦 Building order management service for AMD64..."
docker buildx build \
    --platform linux/amd64 \
    --tag $ORDER_IMAGE:$TAG \
    --push \
    ../order-management

echo "✅ Successfully built and pushed images:"
echo "   - $INVENTORY_IMAGE:$TAG"
echo "   - $ORDER_IMAGE:$TAG"

# Step 2: Get Diagrid Catalyst project endpoints
echo ""
echo "🌐 Getting Diagrid Catalyst project endpoints..."
export DAPR_HTTP_ENDPOINT=$(diagrid project get $CATALYST_PROJECT --output json | jq -r '.status.endpoints.http.url')
export DAPR_GRPC_ENDPOINT=$(diagrid project get $CATALYST_PROJECT --output json | jq -r '.status.endpoints.grpc.url')

# Get Diagrid Catalyst API keys for each app
echo "🔐 Getting Diagrid Catalyst API keys..."
export INVENTORY_API_KEY=$(diagrid appid get $INVENTORY_APP_NAME --output json | jq -r '.status.apiToken')
export ORDER_API_KEY=$(diagrid appid get $ORDER_APP_NAME --output json | jq -r '.status.apiToken')

# Update or append Catalyst endpoints and API keys to .env
# Helper function to update or append env variable
update_or_append_env() {
    local var_name="$1"
    local var_value="$2"
    
    if grep -q "^export ${var_name}=" .env 2>/dev/null; then
        # Update existing value
        sed -i '' "s|^export ${var_name}=.*|export ${var_name}=\"${var_value}\"|" .env
    else
        # Append new value
        echo "export ${var_name}=\"${var_value}\"" >> .env
    fi
}

# Add blank line if appending for the first time
if ! grep -q "^export DAPR_HTTP_ENDPOINT=" .env 2>/dev/null; then
    echo "" >> .env
fi

update_or_append_env "DAPR_HTTP_ENDPOINT" "$DAPR_HTTP_ENDPOINT"
update_or_append_env "DAPR_GRPC_ENDPOINT" "$DAPR_GRPC_ENDPOINT"
update_or_append_env "INVENTORY_API_KEY" "$INVENTORY_API_KEY"
update_or_append_env "ORDER_API_KEY" "$ORDER_API_KEY"

# Step 3: Deploy to Azure Container Apps
echo ""
echo "🚀 Deploying to Azure Container Apps..."

# Deploy inventory service
echo "📦 Deploying inventory service..."
az containerapp create \
    --name $INVENTORY_APP_NAME \
    --resource-group $RESOURCE_GROUP \
    --environment $CONTAINER_APPS_ENVIRONMENT_1 \
    --image $INVENTORY_IMAGE:$TAG \
    --target-port 8080 \
    --ingress external \
    --env-vars \
        DAPR_HTTP_ENDPOINT="$DAPR_HTTP_ENDPOINT" \
        DAPR_GRPC_ENDPOINT="$DAPR_GRPC_ENDPOINT" \
        DAPR_API_TOKEN="$INVENTORY_API_KEY" \
        PUBSUB_COMPONENT="azsb" \
    --query properties.configuration.ingress.fqdn

# Deploy order management service
echo "📦 Deploying order management service..."
az containerapp create \
    --name $ORDER_APP_NAME \
    --resource-group $RESOURCE_GROUP \
    --environment $CONTAINER_APPS_ENVIRONMENT_2 \
    --image $ORDER_IMAGE:$TAG \
    --target-port 8080 \
    --ingress external \
    --env-vars \
        DAPR_HTTP_ENDPOINT="$DAPR_HTTP_ENDPOINT" \
        DAPR_GRPC_ENDPOINT="$DAPR_GRPC_ENDPOINT" \
        DAPR_API_TOKEN="$ORDER_API_KEY" \
        PUBSUB_COMPONENT="azsb" \
    --query properties.configuration.ingress.fqdn

# Get application URLs
INVENTORY_URL=$(az containerapp show \
    --name $INVENTORY_APP_NAME \
    --resource-group $RESOURCE_GROUP \
    --query properties.configuration.ingress.fqdn -o tsv)

ORDER_URL=$(az containerapp show \
    --name $ORDER_APP_NAME \
    --resource-group $RESOURCE_GROUP \
    --query properties.configuration.ingress.fqdn -o tsv)

# Update or append the application URLs to .env
update_or_append_env "INVENTORY_URL" "$INVENTORY_URL"
update_or_append_env "ORDER_URL" "$ORDER_URL"

# Update Catalyst App IDs with application URLs
echo ""
echo "🔗 Updating Catalyst App IDs with application URLs..."
diagrid appid update $INVENTORY_APP_NAME --app-endpoint "https://$INVENTORY_URL"
diagrid appid update $ORDER_APP_NAME --app-endpoint "https://$ORDER_URL"

echo "✅ App IDs updated with URLs"

source .env


# Final summary
echo ""
echo "🎉 Build and deployment completed successfully!"
echo ""
echo "📋 Deployment Summary:"
echo "====================="
echo "Resource Group: $RESOURCE_GROUP"
echo "Location: $LOCATION"
echo "Docker Hub Images: $INVENTORY_IMAGE:$TAG, $ORDER_IMAGE:$TAG"
echo "Container Apps Environment 1: $CONTAINER_APPS_ENVIRONMENT_1"
echo "Container Apps Environment 2: $CONTAINER_APPS_ENVIRONMENT_2"
echo ""
echo "🔧 Diagrid Catalyst Configuration:"
echo "Project: $CATALYST_PROJECT"
echo "HTTP Endpoint: $DAPR_HTTP_ENDPOINT"
echo "gRPC Endpoint: $DAPR_GRPC_ENDPOINT"
echo "Inventory API Key: ${INVENTORY_API_KEY:0:10}..."
echo "Order API Key: ${ORDER_API_KEY:0:10}..."
echo ""
echo "🌐 Application URLs:"
echo "Inventory Service: https://$INVENTORY_URL"
echo "Order Management: https://$ORDER_URL"
echo ""
echo "🌐 Images are available on Docker Hub:"
echo "   - https://hub.docker.com/r/$DOCKER_HUB_USERNAME/inventory-service"
echo "   - https://hub.docker.com/r/$DOCKER_HUB_USERNAME/order-management"
echo ""
echo "✨ Ready to test your applications!"
