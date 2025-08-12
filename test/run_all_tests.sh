#!/bin/bash

echo "🔍 Testing Flutter Dev Panel - Complete Test Suite"
echo "=================================================="

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Test counter
TOTAL_TESTS=0
PASSED_TESTS=0

# Function to run tests and track results
run_test() {
    local test_name=$1
    local test_path=$2
    
    echo ""
    echo "Testing $test_name..."
    
    if flutter test $test_path --reporter expanded 2>&1 | grep -q "All tests passed"; then
        echo -e "${GREEN}✅ $test_name: All tests passed${NC}"
        ((PASSED_TESTS++))
    else
        echo -e "${RED}❌ $test_name: Tests failed${NC}"
    fi
    ((TOTAL_TESTS++))
}

# 1. Test Core Package
run_test "Core Package" "test/"

# 2. Test Console Module
run_test "Console Module" "packages/flutter_dev_panel_console/test"

# 3. Test Network Module
run_test "Network Module" "packages/flutter_dev_panel_network/test"

# 4. Test Device Module
run_test "Device Module" "packages/flutter_dev_panel_device/test"

# 5. Test Performance Module
run_test "Performance Module" "packages/flutter_dev_panel_performance/test"

# Summary
echo ""
echo "=================================================="
echo "Test Summary: $PASSED_TESTS/$TOTAL_TESTS passed"

if [ $PASSED_TESTS -eq $TOTAL_TESTS ]; then
    echo -e "${GREEN}✨ All tests passed successfully!${NC}"
    exit 0
else
    echo -e "${RED}⚠️  Some tests failed${NC}"
    exit 1
fi