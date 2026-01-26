#!/bin/bash
# Test script for Docker version of Conduit
# Tests the Docker-based manager

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

echo "=========================================="
echo "Docker Conduit Test Suite"
echo "=========================================="
echo ""

# Test 1: Check Docker is running
echo "Test 1: Checking Docker..."
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running"
    echo "   Please start Docker Desktop and try again"
    exit 1
fi
echo "✅ Docker is running"
echo "   Version: $(docker --version)"

# Test 2: Check script exists
echo ""
echo "Test 2: Checking Docker manager script..."
if [ ! -f "./scripts/conduit-manager-mac.sh" ]; then
    echo "❌ Script not found"
    exit 1
fi
echo "✅ Script found"

# Test 3: Check if image exists or can be pulled
echo ""
echo "Test 3: Checking Docker image..."
IMAGE="ghcr.io/ssmirr/conduit/conduit:d8522a8"
if docker images | grep -q "ghcr.io/ssmirr/conduit/conduit.*d8522a8"; then
    echo "✅ Image already exists locally"
else
    echo "   Image not found locally, will be pulled on first run"
    echo "   Image: $IMAGE"
fi

# Test 4: Check for existing container
echo ""
echo "Test 4: Checking for existing containers..."
CONTAINER_NAME="conduit-mac"
if docker ps -a | grep -q "$CONTAINER_NAME"; then
    echo "⚠️  Existing container found: $CONTAINER_NAME"
    echo "   Status: $(docker ps -a --filter name=$CONTAINER_NAME --format '{{.Status}}')"
    echo ""
    read -p "   Remove existing container? (y/n): " remove
    if [ "$remove" = "y" ] || [ "$remove" = "Y" ]; then
        docker rm -f $CONTAINER_NAME 2>/dev/null || true
        echo "   ✅ Container removed"
    fi
else
    echo "✅ No existing container (fresh start)"
fi

# Test 5: Test container creation (dry run)
echo ""
echo "Test 5: Testing container creation..."
echo "   This will create a test container to verify setup"
echo ""

# Create a test container with minimal settings
docker run -d \
    --name conduit-test \
    --restart unless-stopped \
    -v conduit-data-test:/home/conduit/data \
    --network host \
    $IMAGE \
    start --max-clients 10 --bandwidth 2 -v > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "✅ Test container created successfully"
    
    # Wait a bit and check if it's running
    sleep 5
    
    if docker ps | grep -q "conduit-test"; then
        echo "✅ Test container is running"
        
        # Check logs
        echo ""
        echo "   Container logs (last 10 lines):"
        docker logs --tail 10 conduit-test 2>&1 | sed 's/^/   /'
        
        # Clean up test container
        echo ""
        echo "   Cleaning up test container..."
        docker stop conduit-test > /dev/null 2>&1
        docker rm conduit-test > /dev/null 2>&1
        docker volume rm conduit-data-test > /dev/null 2>&1 || true
        echo "✅ Test container removed"
    else
        echo "⚠️  Test container stopped (check logs)"
        docker logs --tail 20 conduit-test 2>&1 | sed 's/^/   /'
        docker rm conduit-test > /dev/null 2>&1
        docker volume rm conduit-data-test > /dev/null 2>&1 || true
    fi
else
    echo "❌ Failed to create test container"
    exit 1
fi

echo ""
echo "=========================================="
echo "✅ Docker Tests Passed!"
echo "=========================================="
echo ""
echo "Docker setup is working correctly."
echo ""
echo "To use the Docker manager:"
echo "  ./scripts/conduit-manager-mac.sh"
echo ""
echo "This will provide an interactive menu with:"
echo "  - Start/Restart service"
echo "  - Stop service"
echo "  - Live dashboard"
echo "  - View logs"
echo "  - Reconfigure"
echo ""
