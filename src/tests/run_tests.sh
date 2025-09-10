#!/bin/bash
# Main test runner script

echo "Starting NetSnmp Enterprise test suite..."
echo "==========================================="

# Run configuration tests
echo "Running configuration tests..."
./test_config.sh
if [[ $? -ne 0 ]]; then
    echo "Configuration tests failed! ❌"
    exit 1
fi

# Run scanner tests
echo "Running scanner tests..."
./test_scanner.sh
if [[ $? -ne 0 ]]; then
    echo "Scanner tests failed! ❌"
    exit 1
fi

# Run integration tests
echo "Running integration tests..."
./integration.sh
if [[ $? -ne 0 ]]; then
    echo "Integration tests failed! ❌"
    exit 1
fi

echo "==========================================="
echo "All tests passed successfully! ✅"
echo "NetSnmp Enterprise is ready for deployment"