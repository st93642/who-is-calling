#!/bin/bash

echo "Testing Latvian Government Website URLs"
echo "========================================"

# Create temporary file to store results
temp_file="/tmp/url_test_results.txt"
> "$temp_file"

# Read JSON and extract URLs
jq -r '.[] | "\(.name)|\(.url)|\(.category)"' government_websites.json | while IFS='|' read -r name url category; do
    echo -n "Testing $name ... "
    
    # Try HTTP first, then HTTPS if needed
    response=$(curl -s -o /dev/null -w "%{http_code}" --max-time 8 "$url" 2>/dev/null)
    
    if [[ "$response" =~ ^(200|301|302)$ ]]; then
        echo "✓ VALID"
        echo "$name|$url|$category|VALID" >> "$temp_file"
    else
        # Try with https if http failed
        if [[ ! "$url" =~ ^https:// ]]; then
            https_url="https://${url#http://}"
            response=$(curl -s -o /dev/null -w "%{http_code}" --max-time 8 "$https_url" 2>/dev/null)
            if [[ "$response" =~ ^(200|301|302)$ ]]; then
                echo "✓ VALID (HTTPS)"
                echo "$name|$https_url|$category|VALID" >> "$temp_file"
            else
                echo "✗ FAILED"
                echo "$name|$url|$category|INVALID" >> "$temp_file"
            fi
        else
            echo "✗ FAILED"
            echo "$name|$url|$category|INVALID" >> "$temp_file"
        fi
    fi
done

echo ""
echo "Creating filtered results..."
echo "==========================="

# Create new JSON with only valid URLs
echo "[" > filtered_websites.json

valid_count=0
total_count=0

while IFS='|' read -r name url category status; do
    if [[ "$status" == "VALID" ]]; then
        if [[ $valid_count -gt 0 ]]; then
            echo "," >> filtered_websites.json
        fi
        echo "  {" >> filtered_websites.json
        echo "    \"name\": \"$name\"," >> filtered_websites.json
        echo "    \"url\": \"$url\"," >> filtered_websites.json
        echo "    \"category\": \"$category\"" >> filtered_websites.json
        echo -n "  }" >> filtered_websites.json
        valid_count=$((valid_count + 1))
    fi
    total_count=$((total_count + 1))
done < "$temp_file"

echo "" >> filtered_websites.json
echo "]" >> filtered_websites.json

echo "Results: $valid_count valid URLs out of $total_count total"
echo "Filtered results saved to filtered_websites.json"

# Clean up
rm -f "$temp_file"