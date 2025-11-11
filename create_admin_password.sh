#/bin/bash

set -euo pipefail

echo "creating hash for admin password"

NEW_PASSWORD="${1:-secret}"
IMAGE_NAME="opensearchproject/opensearch:3.3.2"
TOOLS_PATH="/usr/share/opensearch/plugins/opensearch-security/tools"

HASH=$(docker run --rm "$IMAGE_NAME" bash -c "cd $TOOLS_PATH && chmod +x hash.sh && ./hash.sh -p '$NEW_PASSWORD'")

echo "your hashed admin password you want to copy into .env \n"
echo "${HASH}"