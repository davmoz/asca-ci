#!/bin/sh
set -e

CONFIG_FILE="/srv/config.lua"

# If no config.lua exists, create one from the template
if [ ! -f "$CONFIG_FILE" ]; then
    cp /srv/config.lua.dist "$CONFIG_FILE"
fi

# Override config.lua values from environment variables
# This allows docker-compose.yml environment vars to take effect
if [ -n "$MYSQL_HOST" ]; then
    sed -i "s|^mysqlHost = .*|mysqlHost = \"$MYSQL_HOST\"|" "$CONFIG_FILE"
fi

if [ -n "$MYSQL_PORT" ]; then
    sed -i "s|^mysqlPort = .*|mysqlPort = $MYSQL_PORT|" "$CONFIG_FILE"
fi

if [ -n "$MYSQL_USER" ]; then
    sed -i "s|^mysqlUser = .*|mysqlUser = \"$MYSQL_USER\"|" "$CONFIG_FILE"
fi

if [ -n "$MYSQL_PASSWORD" ]; then
    sed -i "s|^mysqlPass = .*|mysqlPass = \"$MYSQL_PASSWORD\"|" "$CONFIG_FILE"
fi

if [ -n "$MYSQL_DATABASE" ]; then
    sed -i "s|^mysqlDatabase = .*|mysqlDatabase = \"$MYSQL_DATABASE\"|" "$CONFIG_FILE"
fi

if [ -n "$SERVER_IP" ]; then
    sed -i "s|^ip = .*|ip = \"$SERVER_IP\"|" "$CONFIG_FILE"
fi

exec /bin/tfs "$@"
