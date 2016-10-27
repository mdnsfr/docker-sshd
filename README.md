# docker-sshd
Simple quick SSHD docker image for ephemeral access

## Configuration

The configuration is done via ENV variables

- USERNAME : account login (default="user")
- PASSWORD : account password (default is no password)
- PUBKEY : account ssh public key (default is no pubkey)
- USERID : posix uid (default=1000)
- GROUPID : posix gid (default=1000)
- USERDIR : account home directory (default=/data)

Both PASSWORD and PUBKEY variables are optionnal, but a SSHD server without any credential would be useless. Maybe you want to use this docker image to try hacking OpenSSH daemon.

You can freely setup both variables to enable password access AND public key access.

## Usage

Here is an example with all options :

```
docker run -it --rm \
  -e "USERNAME=mylogin" \
  -e "PASSWORD=kadl3okZ9JEjez" \
  -e "PUBKEY=ssh-rsa AAA[...]DSLK= comment" \
  -e "USERID=1005" \
  -e "GROUPID=1020" \
  -e "USERDIR=/srv/myhome" \
  mdns/sshd
```
