#!/usr/bin/env bash

# TODO: disallow root access
# BUT! non-sudoer user needs to 'service ssh start' somehow, when the container is first created
# maybe autostart this when the container is first created as a root user?

## Start the ssh server inside the container
if service ssh status | grep -q "sshd is running"; then
    echo "container_root_start: sshd is already running"
else
    echo "container_root_start: attempting to start sshd"
    service ssh start && echo "container_root_start: sshd started" || echo "container_root_start: sshd failed to start"
fi