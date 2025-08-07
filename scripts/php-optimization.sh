#!/bin/bash

# PHP Runtime Configuration Optimization Script
# This script handles runtime PHP configuration adjustments

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}[PHP-Optimization] Starting PHP configuration optimization...${NC}"

# Get PHP version from environment or default to 8.4
PHP_VERSION=${PHP_VERSION:-8.4}

# Ensure PHP configuration directories exist
PHP_CONF_DIR="/etc/php/${PHP_VERSION}"
PHP_FPM_CONF_DIR="${PHP_CONF_DIR}/fpm/conf.d"
PHP_CLI_CONF_DIR="${PHP_CONF_DIR}/cli/conf.d"

echo -e "${BLUE}[PHP-Optimization] Using PHP version: ${PHP_VERSION}${NC}"

# Create a configuration file to disable problematic extensions that are already loaded
cat > "${PHP_FPM_CONF_DIR}/99-pterodactyl-optimization.ini" << 'EOF'
; Pterodactyl Nginx Egg PHP Optimization
; This file prevents double-loading of extensions that are already loaded by package manager

; Ensure core extensions are not explicitly loaded again (they're loaded by package manager)
; extension=mysqli     ; Disabled - loaded by package
; extension=pdo_mysql  ; Disabled - loaded by package  
; extension=mbstring   ; Disabled - loaded by package
; extension=fileinfo   ; Disabled - loaded by package
; extension=exif       ; Disabled - loaded by package

; MySQLND optimizations
mysqlnd.collect_statistics = On
mysqlnd.collect_memory_statistics = Off

; Performance optimizations
realpath_cache_size = 4096k
realpath_cache_ttl = 120
opcache.enable = 1
opcache.memory_consumption = 256
opcache.interned_strings_buffer = 8
opcache.max_accelerated_files = 10000
opcache.revalidate_freq = 60
opcache.fast_shutdown = 1

; Session optimization
session.save_handler = files
session.save_path = "/home/container/tmp"

; Log optimization  
log_errors = On
log_errors_max_len = 1024
ignore_repeated_errors = On
ignore_repeated_source = Off
EOF

# Copy the same configuration to CLI
cp "${PHP_FPM_CONF_DIR}/99-pterodactyl-optimization.ini" "${PHP_CLI_CONF_DIR}/99-pterodactyl-optimization.ini"

echo -e "${GREEN}[PHP-Optimization] PHP configuration optimization completed${NC}"

# Verify extension loading status
echo -e "${YELLOW}[PHP-Optimization] Checking PHP extension status...${NC}"

# Check if PHP binary exists for this version
if command -v "php${PHP_VERSION}" >/dev/null 2>&1; then
    echo -e "${GREEN}[PHP-Optimization] PHP ${PHP_VERSION} binary found${NC}"
    
    # Check if problematic extensions are loaded properly
    if "php${PHP_VERSION}" -m | grep -q "mysqli"; then
        echo -e "${GREEN}[PHP-Optimization] ✓ MySQLi extension loaded${NC}"
    else
        echo -e "${RED}[PHP-Optimization] ✗ MySQLi extension NOT loaded${NC}"
    fi
    
    if "php${PHP_VERSION}" -m | grep -q "pdo_mysql"; then
        echo -e "${GREEN}[PHP-Optimization] ✓ PDO MySQL extension loaded${NC}"
    else
        echo -e "${RED}[PHP-Optimization] ✗ PDO MySQL extension NOT loaded${NC}"
    fi
    
    if "php${PHP_VERSION}" -m | grep -q "mysqlnd"; then
        echo -e "${GREEN}[PHP-Optimization] ✓ MySQL Native Driver loaded${NC}"
    else
        echo -e "${YELLOW}[PHP-Optimization] ⚠ MySQL Native Driver not explicitly listed (may be built-in)${NC}"
    fi
    
else
    echo -e "${YELLOW}[PHP-Optimization] PHP ${PHP_VERSION} binary not found, skipping extension check${NC}"
fi

echo -e "${BLUE}[PHP-Optimization] PHP optimization script completed${NC}"
