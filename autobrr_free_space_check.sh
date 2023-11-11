#!/bin/sh

# How much space is considered minimum
reqSpace=250000000

# qBittorrent details
QBT_HOST='https://qbittorrent.autobrr.tardis.averagesizedbarcelona.com'
QBT_PORT='443'
QBT_USERNAME='admin'
QBT_PASSWORD='adminadmin'

# API Endpoints
LOGIN_ENDPOINT="${QBT_HOST}:${QBT_PORT}/api/v2/auth/login"
FREE_SPACE_ENDPOINT="${QBT_HOST}:${QBT_PORT}/api/v2/sync/maindata"

# Temporary cookie jar file
COOKIE_JAR="$(mktemp)"

# Function to remove temporary files
cleanup() {
	rm -f "$COOKIE_JAR"
	if [ $check_outcome -eq 0 ]; then
		echo "Free space check passed"
	else
		echo "Free space check failed"
	fi

	exit $check_outcome
}

# Initialize a var to track check status
check_outcome=1
# Login to qBittorrent
login_response=$(curl -s -c "$COOKIE_JAR" -d "username=$QBT_USERNAME&password=$QBT_PASSWORD" "$LOGIN_ENDPOINT")
if echo "$login_response" | grep -q "Ok."; then
	# Get main data
	main_data=$(curl -s -b "$COOKIE_JAR" "$FREE_SPACE_ENDPOINT")
	free_space=$(echo "$main_data" | jq '.server_state.free_space_on_disk')

	echo "Free space minimum to download releases: $reqSpace B"
	if [ -n "$free_space" ] && [ "$free_space" != "null" ]; then
		echo "Free space in the downloads directory: $free_space B"
		if [ "${free_space}" -le "${reqSpace}" ]; then
			echo "Not enough space for release"
		else
			check_outcome=0
		fi
	else
		echo "Failed to retrieve free space information."
	fi
else
	echo "Failed to log in to qBittorrent."
fi

# Cleanup
cleanup
