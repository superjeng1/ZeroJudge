#!/bin/bash
if [ -z ${SSH_HOST+x} ]; then
  SSH_HOST=`/sbin/ip route|awk '/default/ { print $3 }'`
fi
if [ -z ${SSH_USER+x} ]; then
  SSH_USER="root"
fi
ssh-keyscan -H $SSH_HOST >> ~/.ssh/known_hosts

cat << EOF > /bin/lxc-attach
#!/bin/bash
ssh $SSH_USER@$SSH_HOST lxc-attach "\$(printf ' %q ' "\$@")"
EOF

chmod 755 /bin/lxc-attach

exec catalina.sh run
