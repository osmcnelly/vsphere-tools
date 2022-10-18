<<<<<<< HEAD
#! /bin/sh

> ~/configcheckout
Settings="Banner,IgnoreRhosts,HostbasedAuthentication,PermitRootLogin,PermitEmptyPasswords.PermitUserEnvironment,GSSAPIAuthentication,KerberosAuthentication,StrictModes,Compression,GatewayPorts,X11Forwarding,AcceptEnv,PermitTunnel,ClientAliveCountMax,ClientAliveInterval,MaxSessions,Ciphers"

Field_Separator=$IFS
IFS=,

for val in $Settings; do
grep -i "^${val}" /etc/ssh/sshd_config >> ~/configcheckout
done

IFS=$Field_Separator

echo " " >> ~/configcheckout

grep -i "^password" /etc/pam.d/passwd | grep sufficient >> ~/configcheckout
echo " " >> ~/configcheckout

ls -la /etc/ssh/keys-root/authorized_keys >> ~/configcheckout
echo " " >> ~/configcheckout
=======
#! /bin/bash

SettingArray=("Banner" "IgnoreRhosts" "HostbasedAuthentication" "PermitRootLogin" \
    "PermitEmptyPasswords" "PermitUserEnvironment" "GSSAPIAuthentication" \
    "KerberosAuthentication" "StrictModes" "Compression" "GatewayPorts" \
    "X11Forwarding" "AcceptEnv" "PermitTunnel" "ClientAliveCountMax" \
    "ClientAliveInterval" "MaxSessions" "Ciphers")

for val in ${SettingArray[*]}; do
grep -i "^${val}" /etc/ssh/sshd_config >> ~/configcheckout
done

grep -i "^password" /etc/pam.d/passwd | grep sufficient >> ~/configcheckout

cat /etc/ssh/keys-root/authorized_keys >> ~/configcheckout
>>>>>>> 785117377df1627981529a6918e5835668af8282

/usr/lib/vmware/secureboot/bin/secureBoot.py -s >> ~/configcheckout

exit 0