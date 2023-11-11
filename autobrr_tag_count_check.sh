#!/bin/sh

# Tag name
tag_to_count="${1}"
tag_limit="${2}"
less_than="${3}"

# qBittorrent details
QBT_HOST='https://qbittorrent.autobrr.tardis.averagesizedbarcelona.com'
QBT_PORT='443'
QBT_USERNAME='admin'
QBT_PASSWORD='adminadmin'

# API Endpoints
LOGIN_ENDPOINT="${QBT_HOST}:${QBT_PORT}/api/v2/auth/login"
TORRENT_LIST_ENDPOINT="${QBT_HOST}:${QBT_PORT}/api/v2/torrents/info"

# Temporary cookie jar file
COOKIE_JAR="$(mktemp)"

# Function to remove temporary files
cleanup() {
	rm -f "$COOKIE_JAR"
	if [ $check_outcome -eq 0 ]; then
		echo "Tag count check passed"
	else
		echo "Tag count check failed"
	fi

	exit $check_outcome
}

# Initialize a var to track check status
check_outcome=1
# Login to qBittorrent
login_response=$(curl -s -c "$COOKIE_JAR" -d "username=$QBT_USERNAME&password=$QBT_PASSWORD" "$LOGIN_ENDPOINT")
if echo "$login_response" | grep -q "Ok."; then
	# Get main data
	main_data=$(curl -s -b "$COOKIE_JAR" "$TORRENT_LIST_ENDPOINT")

	# Count the number of torrents with the tag "tag1"
	tagged_count=$(echo "$main_data" | jq '[.[] | select(.tags | contains("'${tag_to_count}'"))] | length')

	echo "Number of torrents tagged with '${tag_to_count}': $tagged_count"
	echo "Limit: ${tag_limit}"
	if [ "$tagged_count" -eq "${tag_limit}" ]; then
		echo "${tagged_count} is equal to ${tag_limit}"
		check_outcome=0
	fi
	if [ -z "${less_than}" ]; then
		if [ "$tagged_count" -gt "${tag_limit}" ]; then
			echo "${tagged_count} is greater than ${tag_limit}"
			check_outcome=0
		fi
	else
		echo "Less-than mode"
		if [ "$tagged_count" -lt "${tag_limit}" ]; then
			echo "${tagged_count} is less than ${tag_limit}"
			check_outcome=0
		fi
	fi
else
	echo "Failed to log in to qBittorrent."
fi

# Cleanup
cleanup
