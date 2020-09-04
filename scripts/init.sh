#!/bin/bash
if [ -z ${SSH_HOST+x} ]; then
  SSH_HOST=`/sbin/ip route|awk '/default/ { print $3 }'`
fi
if [ -z ${SSH_USER+x} ]; then
  SSH_USER="root"
fi
if [ -z ${TOMCAT_SSL_ENABLED+x} ]; then
  cp -n /usr/local/tomcat/webapps/ROOT/WEB-INF/web_http.xml /usr/local/tomcat/webapps/ROOT/WEB-INF/web.xml
else
  cp -n /usr/local/tomcat/webapps/ROOT/WEB-INF/web_https.xml /usr/local/tomcat/webapps/ROOT/WEB-INF/web.xml
fi
ssh-keyscan -H $SSH_HOST > ~/.ssh/known_hosts

cat << EOF > /bin/lxc-attach
#!/bin/bash
ssh $SSH_USER@$SSH_HOST lxc-attach "\$(printf ' %q ' "\$@")"
EOF

chmod 755 /bin/lxc-attach

exec catalina.sh run
