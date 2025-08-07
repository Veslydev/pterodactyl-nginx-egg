#!/bin/bash
cd /home/container

# Ensure required directories exist with proper ownership
mkdir -p /home/container/logs /home/container/tmp /home/container/www
chown -R container:container /home/container/logs /home/container/tmp

# Make internal Docker IP address available to processes.
INTERNAL_IP=$(ip route get 1 | awk '{print $(NF-2);exit}')
export INTERNAL_IP

# Replace Startup Variables
MODIFIED_STARTUP=$(echo -e ${STARTUP} | sed -e 's/{{/${/g' -e 's/}}/}/g')
echo -e ":/home/container$ ${MODIFIED_STARTUP}"

# Run the Server
eval ${MODIFIED_STARTUP}
