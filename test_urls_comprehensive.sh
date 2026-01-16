#!/bin/bash

echo "Testing Latvian Government Website URLs"
echo "======================================="

# Create arrays to store results
declare -a valid_urls=()
declare -a invalid_urls=()

# Read JSON and test each URL
jq -c '.[]' government_websites.json | while read -r entry; do
    name=$(echo "$entry" | jq -r '.name')
    url=$(echo "$entry" | jq -r '.url')
    category=$(echo "$entry" | jq -r '.category')
    
    echo -n "Testing $name ... "
    
    # Test URL with timeout
    response=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$url" 2>/dev/null)
    
    if [[ "$response" =~ ^(200|301|302)$ ]]; then
        echo "✓ VALID ($response)"
        echo "VALID|$name|$url|$category" >> /tmp/valid_urls.txt
    else
        echo "✗ FAILED ($response)"
        echo "INVALID|$name|$url|$category" >> /tmp/invalid_urls.txt
    fi
done

echo ""
echo "Creating final filtered list..."

# Create the filtered JSON
echo "[" > filtered_government_websites.json

first=true
while IFS='|' read -r status name url category; do
    if [[ "$status" == "VALID" ]]; then
        if [[ "$first" != true ]]; then
            echo "," >> filtered_government_websites.json
        fi
        first=false
        
        echo "  {" >> filtered_government_websites.json
        echo "    \"name\": \"$name\"," >> filtered_government_websites.json
        echo "    \"url\": \"$url\"," >> filtered_government_websites.json
        echo "    \"category\": \"$category\"" >> filtered_government_websites.json
        echo -n "  }" >> filtered_government_websites.json
    fi
done < /tmp/valid_urls.txt

echo "" >> filtered_government_websites.json
echo "]" >> filtered_government_websites.json

# Count results
valid_count=$(wc -l < /tmp/valid_urls.txt)
total_count=$(jq '. | length' government_websites.json)

echo ""
echo "RESULTS:"
echo "========"
echo "Total URLs tested: $total_count"
echo "Valid URLs found: $valid_count"
echo "Success rate: $(echo "scale=1; $valid_count * 100 / $total_count" | bc)%"

# Clean up temp files
rm -f /tmp/valid_urls.txt /tmp/invalid_urls.txt

echo ""
echo "Filtered results saved to: filtered_government_websites.json"