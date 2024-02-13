#! /bin/sh

> ~/configcheckout
Settings="Banner,IgnoreRhosts,HostbasedAuthentication,PermitRootLogin,PermitEmptyPasswords,PermitUserEnvironment,GSSAPIAuthentication,KerberosAuthentication,StrictModes,Compression,GatewayPorts,X11Forwarding,AcceptEnv,PermitTunnel,ClientAliveCountMax,ClientAliveInterval,MaxSessions,Ciphers"

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

/usr/lib/vmware/secureboot/bin/secureBoot.py -s >> ~/configcheckout

exit 0