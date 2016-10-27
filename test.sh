#!/bin/bash

[ "$SSHPORT" = "" ] && SSHPORT="8022"

DEFAULTUSERNAME="user"
DEFAULTUSERID="1000"
DEFAULTGROUPID="1000"

RUNID="SSHDTEST$SSHPORT$$"
PASSWORD=$(openssl passwd $RUNID)
echo "Test $RUNID"
echo "Using password $PASSWORD"
echo "Generating SSH key for test"

ssh-keygen -N "" -f $RUNID.key
[ ! -e "$RUNID.key" ] && echo "Cannot generate $RUNID.key" && exit 1

SSHOPT="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
SSHCMD="ssh -p $SSHPORT $SSHOPT 127.0.0.1"
SSHPASS="sshpass -p$PASSWORD "

I=0
function nextTest { I=$(( $I + 1 )); echo "Test $I: $@"; TEST="$RUNID-test$I"; }
function waitTcpPort { while true; do sleep 1; nc -z $1 $2 && break; done ;}
function testSuccess { echo "ALL TESTS ARE OK"; }
function testFail { echo "FAILURE $@"; echo "Dock ID : $DID"; exit 1; }

function testUsername {
  EXPECTEDNAME="$1"; shift; CMDLINE="$@"
  R=$($@ whoami 2>/dev/null)
  [ "$R" = "$EXPECTEDNAME" ] || testFail "username is not '$EXPECTEDNAME'"
}

function testUserID {
  EXPECTEDID="$1" ; shift ; CMDLINE="$@"
  R=$($@ 'id -u' 2>/dev/null)
  [ "$R" = "$EXPECTEDID" ] || testFail "user id is not $EXPECTEDID"
}
function testGroupID {
  EXPECTEDID="$1" ; shift ; CMDLINE="$@"
  R=$($@ 'id -g' 2>/dev/null)
  [ "$R" = "$EXPECTEDID" ] || testFail "group id is not $EXPECTEDID"
}
function testIsSudoer {
  CMDLINE="$@"
  R=$($@ ' sudo whoami ' 2>/dev/null)
  [ "$R" = "root" ] || testFail "User is not sudoer"
}
function testIsNotSudoer {
  CMDLINE="$@"
  R=$($@ ' sudo whoami ' 2>/dev/null)
  [ "$R" = "root" ] && testFail "User is sudoer and should not be"
}

nextTest "Password"
    DID=$(docker run -d --name $TEST -e "PASSWORD=$PASSWORD" -p $SSHPORT:22 mdns/sshd)
    sleep 1
    TESTCMD="$SSHPASS $SSHCMD -l $DEFAULTUSERNAME"

    testUsername $DEFAULTUSERNAME "$TESTCMD"
    testUserID $DEFAULTUSERID "$TESTCMD"
    testGroupID $DEFAULTGROUPID "$TESTCMD"
    testIsNotSudoer "$TESTCMD"

    DID=$(docker rm -f $DID)

nextTest "Password + username"
    DID=$(docker run -d --name $TEST -e "USERNAME=mylogin" -e "PASSWORD=$PASSWORD" -p $SSHPORT:22 mdns/sshd)
    sleep 1
    TESTCMD="$SSHPASS $SSHCMD -l mylogin"

    testUsername mylogin "$TESTCMD"
    testUserID $DEFAULTUSERID "$TESTCMD"
    testGroupID $DEFAULTGROUPID "$TESTCMD"
    testIsNotSudoer "$TESTCMD"

    DID=$(docker rm -f $DID)


nextTest "Password + user id"
    DID=$(docker run -d --name $TEST -e "USERID=1023" -e "PASSWORD=$PASSWORD" -p $SSHPORT:22 mdns/sshd)
    sleep 1
    TESTCMD="$SSHPASS $SSHCMD -l $DEFAULTUSERNAME"

    testUsername $DEFAULTUSERNAME "$TESTCMD"
    testUserID 1023 "$TESTCMD"
    testGroupID $DEFAULTGROUPID "$TESTCMD"
    testIsNotSudoer "$TESTCMD"

    DID=$(docker rm -f $DID)

nextTest "Password + group id"
    DID=$(docker run -d --name $TEST -e "GROUPID=1025" -e "PASSWORD=$PASSWORD" -p $SSHPORT:22 mdns/sshd)
    sleep 1
    TESTCMD="$SSHPASS $SSHCMD -l $DEFAULTUSERNAME"

    testUsername $DEFAULTUSERNAME "$TESTCMD"
    testUserID $DEFAULTUSERID "$TESTCMD"
    testGroupID 1025 "$TESTCMD"
    testIsNotSudoer "$TESTCMD"

    DID=$(docker rm -f $DID)

nextTest "Password + username + user id + group id"
    DID=$(docker run -d --name $TEST -e "USERNAME=thisisme" -e "USERID=1021" -e "GROUPID=1027" -e "PASSWORD=$PASSWORD" -p $SSHPORT:22 mdns/sshd)
    sleep 1
    TESTCMD="$SSHPASS $SSHCMD -l thisisme"

    testUsername thisisme "$TESTCMD"
    testUserID 1021 "$TESTCMD"
    testGroupID 1027 "$TESTCMD"
    testIsNotSudoer "$TESTCMD"

    DID=$(docker rm -f $DID)

nextTest "Sudoer"
    DID=$(docker run -d --name $TEST -e "SUDOER=nopasswd" -e "PASSWORD=$PASSWORD" -p $SSHPORT:22 mdns/sshd)
    sleep 1
    TESTCMD="$SSHPASS $SSHCMD -l $DEFAULTUSERNAME"

    testUsername $DEFAULTUSERNAME "$TESTCMD"
    testUserID $DEFAULTUSERID "$TESTCMD"
    testGroupID $DEFAULTGROUPID "$TESTCMD"
    testIsSudoer "$TESTCMD"

    DID=$(docker rm -f $DID)

nextTest "SSH Key"
    DID=$(docker run -d --name $TEST -e "PUBKEY=$(cat $RUNID.key.pub)" -p $SSHPORT:22 mdns/sshd)
    sleep 1
    TESTCMD="$SSHCMD -l $DEFAULTUSERNAME -i $RUNID.key "

    testUsername $DEFAULTUSERNAME "$TESTCMD"
    testUserID $DEFAULTUSERID "$TESTCMD"
    testGroupID $DEFAULTGROUPID "$TESTCMD"
    testIsNotSudoer "$TESTCMD"

    DID=$(docker rm -f $DID)

nextTest "SSH Key + Sudoer"
    DID=$(docker run -d --name $TEST -e "SUDOER=nopasswd" -e "PUBKEY=$(cat $RUNID.key.pub)" -p $SSHPORT:22 mdns/sshd)
    sleep 1
    TESTCMD="$SSHCMD -l $DEFAULTUSERNAME -i $RUNID.key"

    testUsername $DEFAULTUSERNAME "$TESTCMD"
    testUserID $DEFAULTUSERID "$TESTCMD"
    testGroupID $DEFAULTGROUPID "$TESTCMD"
    testIsSudoer "$TESTCMD"

    DID=$(docker rm -f $DID)



nextTest "Password + SSH Key"
    DID=$(docker run -d --name $TEST -e "PUBKEY=$(cat $RUNID.key.pub)" -e "PASSWORD=$PASSWORD" -p $SSHPORT:22 mdns/sshd)
    sleep 1

    echo "  - Testing with pubkey"
    TESTCMD="$SSHCMD -l $DEFAULTUSERNAME -i $RUNID.key"
    testUsername $DEFAULTUSERNAME "$TESTCMD"
    testUserID $DEFAULTUSERID "$TESTCMD"
    testGroupID $DEFAULTGROUPID "$TESTCMD"
    testIsNotSudoer "$TESTCMD"

    echo "  - Testing with password"
    TESTCMD="$SSHPASS $SSHCMD -l $DEFAULTUSERNAME"
    testUsername $DEFAULTUSERNAME "$TESTCMD"
    testUserID $DEFAULTUSERID "$TESTCMD"
    testGroupID $DEFAULTGROUPID "$TESTCMD"
    testIsNotSudoer "$TESTCMD"

    DID=$(docker rm -f $DID)



nextTest "Password + SSH Key + Sudoer"
    DID=$(docker run -d --name $TEST -e "SUDOER=nopasswd" -e "PUBKEY=$(cat $RUNID.key.pub)" -e "PASSWORD=$PASSWORD" -p $SSHPORT:22 mdns/sshd)
    sleep 1

    echo "  - Testing with pubkey"
    TESTCMD="$SSHCMD -l $DEFAULTUSERNAME -i $RUNID.key"
    testUsername $DEFAULTUSERNAME "$TESTCMD"
    testUserID $DEFAULTUSERID "$TESTCMD"
    testGroupID $DEFAULTGROUPID "$TESTCMD"
    testIsSudoer "$TESTCMD"

    echo "  - Testing with password"
    TESTCMD="$SSHPASS $SSHCMD -l $DEFAULTUSERNAME"
    testUsername $DEFAULTUSERNAME "$TESTCMD"
    testUserID $DEFAULTUSERID "$TESTCMD"
    testGroupID $DEFAULTGROUPID "$TESTCMD"
    testIsSudoer "$TESTCMD"

    DID=$(docker rm -f $DID)

nextTest "Password + SSH Key + username + user id + group id + Sudoer"
    DID=$(docker run -d --name $TEST -e "SUDOER=nopasswd" -e "USERNAME=admin" -e "USERID=1337" -e "GROUPID=1666" -e "PUBKEY=$(cat $RUNID.key.pub)" -e "PASSWORD=$PASSWORD" -p $SSHPORT:22 mdns/sshd)
    sleep 1

    echo "  - Testing with pubkey"
    TESTCMD="$SSHCMD -l admin -i $RUNID.key"
    testUsername admin "$TESTCMD"
    testUserID 1337 "$TESTCMD"
    testGroupID 1666 "$TESTCMD"
    testIsSudoer "$TESTCMD"

    echo "  - Testing with password"
    TESTCMD="$SSHPASS $SSHCMD -l admin"
    testUsername admin "$TESTCMD"
    testUserID 1337 "$TESTCMD"
    testGroupID 1666 "$TESTCMD"
    testIsSudoer "$TESTCMD"

    DID=$(docker rm -f $DID)


rm $RUNID.key*

testSuccess

exit
docker run -d -it -e "USERNAME=mylogin" \
  -e "PASSWORD=kadl3okZ9JEjez" \
  -e "PUBKEY=ssh-rsa AAA[...]DSLK= comment" \
  -e "USERID=1005" \
  -e "GROUPID=1020" \
  -e "USERDIR=/srv/myhome" \
  mdns/sshd
