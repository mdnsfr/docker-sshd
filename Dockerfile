FROM ubuntu

RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install sudo openssh-server busybox-syslogd -y \
  && apt-get clean \
  && /bin/rm -v /etc/ssh/ssh_host_* \
  && mkdir /var/run/sshd
COPY sshd.sh /sshd.sh
COPY sshd_config /etc/ssh/
CMD /sshd.sh
