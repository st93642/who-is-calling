#!/bin/bash

echo "Testing Latvian Government Website URLs"
echo "========================================"

# Read the JSON file and process each entry
jq -r '.[] | "\(.name) - \(.url)"' government_websites.json | while IFS= read -r line; do
    name=$(echo "$line" | cut -d' ' -f1-2)
    url=$(echo "$line" | sed 's/.* - //')
    
    echo -n "Testing $name ... "
    
    # Try different approaches to test the URL
    response=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$url" 2>/dev/null)
    
    if [[ "$response" =~ ^(200|301|302)$ ]]; then
        echo "✓ OK ($response)"
    else
        echo "✗ FAILED ($response)"
    fi
done