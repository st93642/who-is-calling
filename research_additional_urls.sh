#!/bin/bash

echo "Researching Additional Latvian Government Websites"
echo "=============================================="

# Additional municipalities and local governments to test
declare -a additional_urls=(
    "https://saldus.lv"
    "https://www.saldus.lv"
    "https://olaine.lv"
    "https://www.olaine.lv"
    "https://kekava.lv"
    "https://www.kekava.lv"
    "https://limbazi.lv"
    "https://www.limbazi.lv"
    "https://preili.lv"
    "https://www.preili.lv"
    "https://livani.lv"
    "https://www.livani.lv"
    "https://dobele.lv"
    "https://www.dobele.lv"
    "https://jelgava.lv"
    "https://aizkraukle.lv"
    "https://www.aizkraukle.lv"
    "https://jecava.lv"
    "https://www.jecava.lv"
    "https://talsi.lv"
    "https://www.talsi.lv"
    "https://kuldiga.lv"
    "https://ventspilsnovads.lv"
    "https://www.ventspilsnovads.lv"
    "https://saulkrasti.lv"
    "https://www.saulkrasti.lv"
    "https://sigulda.lv"
    "https://www.sigulda.lv"
    "https://adazi.lv"
    "https://www.adazi.lv"
)

working_count=0
> /tmp/additional_working_urls.txt

for url in "${additional_urls[@]}"; do
    echo -n "Testing $url ... "
    response=$(curl -s -o /dev/null -w "%{http_code}" --max-time 8 "$url" 2>/dev/null)
    if [[ "$response" =~ ^(200|301|302)$ ]]; then
        echo "✓ WORKING ($response)"
        echo "$url" >> /tmp/additional_working_urls.txt
        working_count=$((working_count + 1))
    else
        echo "✗ FAILED ($response)"
    fi
done

echo ""
echo "Found $working_count additional working URLs"

# Alternative patterns for ministries and agencies
echo ""
echo "Testing alternative ministry/agency patterns..."

declare -a alt_patterns=(
    "https://www.latvija.gov.lv"
    "https://www.mk.gov.lv"
    "https://www.iem.gov.lv"
    "https://www.fm.gov.lv"
    "https://www.vm.gov.lv"
    "https://www.izm.gov.lv"
    "https://www.em.gov.lv"
    "https://www.zm.gov.lv"
    "https://www.km.gov.lv"
    "https://www.lm.gov.lv"
    "https://www.sam.gov.lv"
    "https://www.varam.gov.lv"
    "https://www.vid.gov.lv"
    "https://www.rs.gov.lv"
    "https://www.vp.gov.lv"
    "https://www.tiesas.gov.lv"
    "https://www.lursoft.lv"
    "https://www.vdi.gov.lv"
    "https://www.vi.gov.lv"
    "https://www.pvd.gov.lv"
    "https://www.lsa.gov.lv"
    "https://www.vmnvd.gov.lv"
    "https://www.riga.lv"
    "https://www.liepaja.lv"
    "https://www.jurmala.lv"
    "https://www.ogre.lv"
    "https://www.tukums.lv"
    "https://www.cesi.lv"
    "https://www.gulbene.lv"
)

alt_working=0
for url in "${alt_patterns[@]}"; do
    echo -n "Testing $url ... "
    response=$(curl -s -o /dev/null -w "%{http_code}" --max-time 8 "$url" 2>/dev/null)
    if [[ "$response" =~ ^(200|301|302)$ ]]; then
        echo "✓ WORKING ($response)"
        echo "$url" >> /tmp/additional_working_urls.txt
        alt_working=$((alt_working + 1))
    else
        echo "✗ FAILED ($response)"
    fi
done

echo ""
echo "Total additional working URLs found: $((working_count + alt_working))"

if [ -f /tmp/additional_working_urls.txt ]; then
    echo ""
    echo "All additional working URLs:"
    cat /tmp/additional_working_urls.txt | sort -u
fi

# Clean up
rm -f /tmp/additional_working_urls.txt