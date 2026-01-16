#!/bin/bash

# Script to verify Latvian government website URLs
echo "Verifying Latvian government website URLs..."
echo "=========================================="

# Read the JSON file and extract URLs
urls=$(jq -r '.[].url' government_websites.json)

valid_count=0
invalid_count=0
total_count=0

for url in $urls; do
    total_count=$((total_count + 1))
    echo -n "Testing $url ... "
    
    # Test if URL is reachable with a 10-second timeout
    if curl -s --max-time 10 --head "$url" | head -n 1 | grep -q "200 OK\|301\|302"; then
        echo "✓ VALID"
        valid_count=$((valid_count + 1))
    else
        echo "✗ INVALID"
        invalid_count=$((invalid_count + 1))
    fi
done

echo "=========================================="
echo "Results: $valid_count valid, $invalid_count invalid out of $total_count total URLs"