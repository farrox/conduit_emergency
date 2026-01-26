#!/bin/bash
# Start the web dashboard for Conduit

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DASHBOARD_DIR="$PROJECT_ROOT/dashboard"

cd "$DASHBOARD_DIR"

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed"
    echo ""
    echo "Install Node.js:"
    echo "  brew install node"
    echo ""
    exit 1
fi

# Check if dependencies are installed
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
fi

# Check if .env exists
if [ ! -f ".env" ]; then
    echo "⚙️  Creating .env file from example..."
    cp .env.example .env
    echo ""
    echo "⚠️  Default password is 'changeme'"
    echo "   Edit dashboard/.env to change it"
    echo ""
fi

# Start the dashboard
echo "🚀 Starting dashboard..."
echo ""
echo "Dashboard will be available at: http://localhost:3000"
echo "Default password: changeme"
echo ""
echo "Press Ctrl+C to stop"
echo ""

node server.js
