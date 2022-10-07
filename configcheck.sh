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

/usr/lib/vmware/secureboot/bin/secureBoot.py -s >> ~/configcheckout

exit 0