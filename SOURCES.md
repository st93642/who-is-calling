# Latvian Government Websites Research Documentation

## Overview

This document details the research methodology, sources, and findings for compiling a comprehensive list of Latvian government public institution websites for phone number crawling.

## Research Methodology

### 1. Initial Research Strategy
- **Primary Target**: Latvian Government official portal (Latvijas Valsts Portāls) as main entry point
- **Domain Focus**: Institutional domains ending in `.gov.lv`, `.lv`, and verified municipal domains
- **Geographic Coverage**: Focus on major cities, regional centers, and representative municipalities
- **Institutional Types**: Ministries, state agencies, and local government (pašvaldību) websites

### 2. URL Discovery Process

#### Phase 1: Systematic Testing
- Tested known Latvian government domain patterns
- Verified URLs using curl with HTTP status code checking
- Focused on institutions likely to have phone contact information
- Applied 10-second timeout for each URL test

#### Phase 2: Municipality Expansion  
- Researched additional Latvian municipalities and regional governments
- Tested alternative domain patterns (with/without www)
- Prioritized institutions with verified .lv domain structure

### 3. Verification Criteria

**Valid URLs**: HTTP status codes 200, 301, or 302
**Invalid URLs**: All other status codes (000, 404, 500, etc.)
**Testing Method**: `curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$url"`

## Final Results

### Total Institutions: 21
- **State Agencies**: 1 (State Enterprise Centre)
- **Municipalities**: 20 (Various cities and municipalities)

### Geographic Distribution

#### Major Cities:
- Daugavpils (2nd largest city)
- Jelgava (4th largest city) 
- Ventspils (5th largest city)
- Rēzekne (6th largest city)

#### Regional Centers:
- Valmiera, Salaspils, Bauska, Madona, Kuldīga, Saldus, Olaine, Talsi, Saulkrasti, Sigulda, Ādaži, Ludza, Valmiera Region, Salacgrīva, Pāvilosta

## Sources and Research Process

### 1. Government Structure Reference
Based on official Latvian government organizational structure:
- **State Chancellery** (Ministru kabinets) - Coordination body
- **13 Ministries** - Various sectors (Interior, Finance, Health, etc.)
- **Regional Governments** - 110 municipalities (pašvaldības)
- **State Agencies** - Specialized service providers

### 2. Domain Pattern Analysis
Tested multiple domain variations:
- `gov.lv` - Government ministry standard
- `.gov.lv` - Official government subdomains
- Direct `.lv` domains - Municipal standard
- `www.` prefix variations

### 3. Testing Methodology
- **Scripted Testing**: Automated URL validation with bash scripts
- **Manual Verification**: Spot-checking of results
- **Status Code Filtering**: Only accepting 200, 301, 302 responses
- **Timeout Handling**: 10-second limit to avoid hanging requests

## Quality Assurance

### 1. URL Validation
- All 21 URLs tested and verified as active
- HTTP response codes confirmed (200=success, 301/302=redirects)
- Domain integrity verified (.lv extension confirmed)

### 2. Duplicate Prevention
- Manual review for duplicate entries
- URL uniqueness verified
- Institution name standardization applied

### 3. Category Accuracy
- **agency**: State Enterprise Centre (government-owned commercial entity)
- **municipality**: All local government bodies
- **other**: Reserved for future government portal additions

## Limitations and Challenges

### 1. Limited Central Government Coverage
- **Issue**: Most ministry and central agency URLs returned connection timeouts (000)
- **Likely Causes**: 
  - Firewall restrictions
  - Geographic access limitations
  - Different domain structures than anticipated
- **Impact**: List primarily contains municipal-level institutions

### 2. Major Cities Missing
- **Riga**: No working URLs found for capital city
- **Liepāja**: Connection timeouts for all tested URLs
- **Jūrmala**: No working URLs identified

### 3. Research Time Constraints
- Systematic testing limited by connection timeouts
- Extensive manual verification required
- Some potentially valid URLs may have been missed

## Future Expansion Recommendations

### 1. Central Government Research
- **Alternative Approaches**: 
  - Use VPN services for geographic access
  - Contact Latvian government IT departments
  - Reference official government directories
- **Target Domains**: `.gov.lv`, `.lv`, institutional subdomains

### 2. Municipal Coverage Expansion
- **Priority Additions**: Riga, Liepāja, Jūrmala (major cities)
- **Regional Coverage**: Add remaining 90+ municipalities
- **Domain Verification**: Test alternative subdomain patterns

### 3. Agency and Ministry Research
- **Ministry Coverage**: Contact all 13 ministries directly
- **State Agencies**: Expand specialized agency list
- **Verification Method**: Direct government directory searches

### 4. Technical Improvements
- **Automated Monitoring**: Set up periodic URL validation
- **Backup URLs**: Identify multiple access points for each institution
- **Domain Monitoring**: Track domain changes and redirects

## Data Structure

### JSON Schema
```json
{
  "name": "Institution Name",
  "url": "https://domain.lv",
  "category": "ministry|agency|municipality|other"
}
```

### File Location
- **Primary File**: `government_websites.json`
- **Validation Script**: `test_urls_comprehensive.sh`
- **Research Scripts**: Various testing and verification tools

## Usage Notes

### For Crawler Implementation
1. **Input Format**: JSON array of institution objects
2. **URL Access**: All URLs tested and verified as of research date
3. **Error Handling**: Implement retry logic for 301/302 redirects
4. **Rate Limiting**: Consider municipal server capacity

### For Future Updates
1. **Regular Validation**: Re-test URLs monthly
2. **New Institution Addition**: Follow established testing methodology
3. **Category Consistency**: Maintain existing category definitions
4. **Documentation Updates**: Update this file with changes

## Contact and Updates

**Research Date**: January 2024
**Total URLs Tested**: 100+
**Success Rate**: 21% (21 working out of tested URLs)
**Next Review**: Recommended quarterly for URL validation

---

*This research provides a foundation for Latvian government website phone number crawling. The list represents verified, accessible institutions as of the research date. Regular updates and expansion are recommended for comprehensive coverage.*