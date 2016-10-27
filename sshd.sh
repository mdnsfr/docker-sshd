#!/bin/bash

[ ! -e /etc/ssh/ssh_host_rsa_key ] && dpkg-reconfigure openssh-server

[ "$USERNAME" = "" ] && USERNAME=user
[ "$USERID" = "" ] && USERID=1000
[ "$GROUPID" = "" ] && GROUPID=1000
[ "$USERSHELL" = "" ] && USERSHELL=/bin/bash
[ "$USERDIR" = "" ] && USERDIR="/home/$USERNAME"

echo "Creating user $USERNAME"
useradd $USERNAME

echo "Checking group $USERNAME"
groupmod -g "$GROUPID" "$USERNAME"

echo "Checking data directory $USERDIR"
[ ! -e "$USERDIR" ] && mkdir -p "$USERDIR" && chown "$USERID":"$GROUPID" "$USERDIR"

echo "Configuring user $USERNAME (uid=$USERID,gid=$GROUPID,dir=$USERDIR)"
usermod -u $USERID -o -g $GROUPID -d $USERDIR -s "$USERSHELL" $USERNAME

# Password
if [ "$PASSWORD" != "" ]
then
  echo "Setting $USERNAME password"
  usermod -p $(openssl passwd "$PASSWORD") "$USERNAME"
  sed -i 's/PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config
  echo '================================================================='
  echo ' Warning : Using a password is less secure than using a SSH key !'
  echo '================================================================='
else
  sed -i 's/PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config
fi

# Public key
if [ "$PUBKEY" != "" ]
then
  mkdir -p "$USERDIR/.ssh"
  chmod 700 "$USERDIR/.ssh"
  chown "$USERID":"$GROUPID" "$USERDIR/.ssh"
  echo "$PUBKEY" > "$USERDIR/.ssh/authorized_keys"
fi

service ssh start
syslogd -n -O /dev/stdout
