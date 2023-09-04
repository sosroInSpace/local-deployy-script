#!/bin/bash
# ------------------------------------------------------------------------------------------------------>
# INSTRUCTIONS:

# 1. run ./deploy <ssh_alias>, <local_wp_content_path>, and <database_name>, and the script will use the provided database name when using mysqldump to extract the SQL dump.
# 2. NOTE: this is for newer instances - path names may need to be changed depending on the server being used.

#-------------------------------------------------------------------------------------------------------->

if [ $# -ne 3 ]; then
  echo "Usage: $0 <ssh_alias> <local_wp_content_path> <database_name>"
  exit 1
fi

ssh_alias="$1"
local_wp_content_path="$2"
database_name="$3"
remote_home_path="/home/bitnami"

# Automatically extract the SQL dump from your local MySQL database
local_sql_file="local_database_dump.sql"
echo "Extracting SQL dump from your local MySQL database for database: $database_name"
mysqldump -u root -proot "$database_name" > "$local_sql_file"

# Copy the entire local wp-content to the remote server
echo "Copying wp-content to the remote server..."
zip -r wp-content.zip "$local_wp_content_path" -x '*node_modules*'
scp wp-content.zip "$ssh_alias:$remote_home_path/stack/wordpress/"

# Copy the extracted SQL dump to your local directory
echo "Copying SQL dump to your local directory..."
scp "$local_sql_file" "$ssh_alias:$remote_home_path/"

# Execute all the steps within a single SSH connection
ssh "$ssh_alias" <<EOF
mv "$remote_home_path/stack/wordpress/wp-content" "$remote_home_path/stack/wordpress/wp-content-old"
unzip -q "$remote_home_path/stack/wordpress/wp-content.zip" -d "$remote_home_path/stack/wordpress/"
mv "$remote_home_path/stack/wordpress/wp-content" "$remote_home_path/stack/wordpress/wp-content"
rm "$remote_home_path/stack/wordpress/wp-content.zip"
rm -rf "$remote_home_path/stack/wordpress/wp-content-old" # Remove wp-content-old from the server
mysql -u bn_wordpress -p"$db_password" -e "drop database bitnami_wordpress; create database bitnami_wordpress;"
mysql -u bn_wordpress -p"$db_password" bitnami_wordpress < "$(basename $local_sql_file)"
rm "$remote_home_path/$(basename $local_sql_file)" # Remove the SQL file from the server
EOF

# Remove wp-content.zip and the local SQL file
rm wp-content.zip
rm "$local_sql_file"

echo "wp-content transferred and updated, SQL operations executed on the remote server, and local files removed."
