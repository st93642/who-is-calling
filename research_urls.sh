#!/bin/bash

echo "Researching Latvian Government Websites"
echo "====================================="

# Test alternative domain patterns for Latvian government sites
echo "Testing alternative domain patterns..."

declare -a test_urls=(
    "https://latvija.gov.lv"
    "https://gov.lv"
    "https://mk.gov.lv"
    "https://iem.gov.lv"
    "https://fm.gov.lv"
    "https://vm.gov.lv"
    "https://izm.gov.lv"
    "https://em.gov.lv"
    "https://zm.gov.lv"
    "https://km.gov.lv"
    "https://lm.gov.lv"
    "https://sam.gov.lv"
    "https://varam.gov.lv"
    "https://vid.gov.lv"
    "https://rs.gov.lv"
    "https://vp.gov.lv"
    "https://tiesas.gov.lv"
    "https://vdi.gov.lv"
    "https://vi.gov.lv"
    "https://pvd.gov.lv"
    "https://lsa.gov.lv"
    "https://vmnvd.gov.lv"
    "https://riga.lv"
    "https://www.riga.lv"
    "https://liepaja.lv"
    "https://www.liepaja.lv"
    "https://jurmala.lv"
    "https://www.jurmala.lv"
    "https://rezekne.lv"
    "https://www.rezekne.lv"
    "https://ogre.lv"
    "https://www.ogre.lv"
    "https://tukums.lv"
    "https://www.tukums.lv"
    "https://kuldiga.lv"
    "https://www.kuldiga.lv"
    "https://cesi.lv"
    "https://www.cesi.lv"
    "https://bauska.lv"
    "https://madona.lv"
    "https://gulbene.lv"
)

working_count=0
for url in "${test_urls[@]}"; do
    echo -n "Testing $url ... "
    response=$(curl -s -o /dev/null -w "%{http_code}" --max-time 8 "$url" 2>/dev/null)
    if [[ "$response" =~ ^(200|301|302)$ ]]; then
        echo "✓ WORKING ($response)"
        echo "$url" >> /tmp/working_urls.txt
        working_count=$((working_count + 1))
    else
        echo "✗ FAILED ($response)"
    fi
done

echo ""
echo "Found $working_count working URLs"
if [ -f /tmp/working_urls.txt ]; then
    echo "Working URLs:"
    cat /tmp/working_urls.txt
fi

# Clean up
rm -f /tmp/working_urls.txt