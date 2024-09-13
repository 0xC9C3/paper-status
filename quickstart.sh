#!/usr/bin/env bash

DOCKER_IMAGE_NAME="ghcr.io/0xc9c3/paper-status:main"

IMAGE_URL="${1:-https://picsum.photos/seed/picsum/800/480}"
REFRESH_INTERVAL="${2:-60}"

# stop on error
set -e

# check if docker is installed
if ! [ -x "$(command -v docker)" ]; then
  echo 'Error: docker is not installed.' >&2
  exit 1
fi

echo "Pulling image: $DOCKER_IMAGE_NAME"

# pull docker image
docker pull $DOCKER_IMAGE_NAME

echo "Creating systemd service"
# install or replace systemd service
cat <<EOF > /etc/systemd/system/paper-status.service
[Unit]
Description=Paper Status service
After=docker.service
Requires=docker.service
StartLimitIntervalSec=300
StartLimitBurst=15

[Service]
Environment="REFRESH_INTERVAL=$REFRESH_INTERVAL"
Environment="IMAGE_URL=$IMAGE_URL"
Restart=always
RestartSec=5
ExecStart=/usr/bin/docker run --pull always --rm --privileged --name paper-status --env REFRESH_INTERVAL=$REFRESH_INTERVAL --env IMAGE_URL=$IMAGE_URL $DOCKER_IMAGE_NAME
ExecStop=/usr/bin/docker stop paper-status

[Install]
WantedBy=multi-user.target
EOF

# reload, enable, start or restart service
systemctl daemon-reload
systemctl enable paper-status
systemctl restart paper-status

echo "Done"


