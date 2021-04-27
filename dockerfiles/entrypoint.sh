#!/bin/bash

# Add local user
# Either use the LOCAL_USER_ID if passed in at runtime or
# fallback

USER_ID=${LOCAL_USER_ID:-9001}

useradd --shell /bin/bash -u $USER_ID -o -c "" developer
usermod -aG docker developer
sudo chmod 666 /var/run/docker.sock
echo "developer ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

chown developer /home/developer
chgrp developer /home/developer

export HOME=/home/developer

export LANG=en_US.UTF-8
cd /home/developer/sdl/sdl_atf/build/bin/RemoteTestingAdapterServer
ifconfig
sudo LD_LIBRARY_PATH="/home/developer/sdl/3rd_party/lib:/home/developer/sdl/3rd_party/x86_64/lib:." -u developer "./RemoteTestingAdapterServer"
EXPOSE 22
/usr/sbin/sshd -d