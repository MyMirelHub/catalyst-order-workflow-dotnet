#!/bin/bash

# Azure Container Apps Demo Deployment Script
# This script sets up Azure resources and deploys the demo applications

set -e  # Exit on any error

# Change to the script's directory
cd "$(dirname "$0")"

echo "Sourcing .env file..."
source .env

echo "🚀 Starting Azure Container Apps Demo Deployment..."

# Check if user is logged in to Azure
echo "📋 Checking Azure login status..."
if ! az account show &> /dev/null; then
    echo "❌ Not logged in to Azure. Please run 'az login' first."
    exit 1
fi

echo "✅ Logged in to Azure"

# Create resource group
echo "📦 Creating resource group: $RESOURCE_GROUP"
az group create --name $RESOURCE_GROUP --location $LOCATION_1

# Create Service Bus namespace
echo "🚌 Creating Service Bus namespace: $SERVICEBUS_NAMESPACE"
az servicebus namespace create \
    --resource-group $RESOURCE_GROUP \
    --name $SERVICEBUS_NAMESPACE \
    --location $LOCATION_1 \
    --sku Standard

# Create Service Bus topics
echo "📨 Creating Service Bus topics..."
az servicebus topic create \
    --name $PROMOTIONS_TOPIC \
    --namespace-name $SERVICEBUS_NAMESPACE \
    --resource-group $RESOURCE_GROUP

az servicebus topic create \
    --name $ORDER_NOTIFICATIONS_TOPIC \
    --namespace-name $SERVICEBUS_NAMESPACE \
    --resource-group $RESOURCE_GROUP

# Get Service Bus connection string
echo "🔑 Getting Service Bus connection string..."
export SB_CONNECTION_STRING=$(az servicebus namespace authorization-rule keys list \
    --resource-group $RESOURCE_GROUP \
    --namespace-name $SERVICEBUS_NAMESPACE \
    --name RootManageSharedAccessKey \
    --query primaryConnectionString -o tsv)

# Update or append Service Bus connection string to .env
if grep -q "^export SB_CONNECTION_STRING=" .env 2>/dev/null; then
    # Update existing value
    sed -i '' "s|^export SB_CONNECTION_STRING=.*|export SB_CONNECTION_STRING=\"$SB_CONNECTION_STRING\"|" .env
else
    # Append new value
    echo "" >> .env
    echo "export SB_CONNECTION_STRING=\"$SB_CONNECTION_STRING\"" >> .env
fi

# Update the .env file sourcing
source .env

# Create Container Apps environment
echo "🌍 Creating Container Apps environment: $CONTAINER_APPS_ENVIRONMENT_1"
az containerapp env create \
    --name $CONTAINER_APPS_ENVIRONMENT_1 \
    --resource-group $RESOURCE_GROUP \
    --location $LOCATION_1

echo "🌍 Creating Container Apps environment: $CONTAINER_APPS_ENVIRONMENT_2"
az containerapp env create \
    --name $CONTAINER_APPS_ENVIRONMENT_2 \
    --resource-group $RESOURCE_GROUP \
    --location $LOCATION_2


echo ""
echo "🎉 Infa Deployment completed successfully!"
echo ""
echo "📋 Deployment Summary:"
echo "====================="
echo "Resource Group: $RESOURCE_GROUP"
echo "Service Bus Namespace: $SERVICEBUS_NAMESPACE"
echo "Container Apps Environment 1: $CONTAINER_APPS_ENVIRONMENT_1"
echo "Container Apps Environment 2: $CONTAINER_APPS_ENVIRONMENT_2"
echo ""
echo "🔑 Service Bus Connection String:"
echo "$SB_CONNECTION_STRING"
echo ""
echo "🧹 To clean up resources later, run:"
echo "az group delete --name $RESOURCE_GROUP --yes --no-wait"
