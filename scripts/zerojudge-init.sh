#!/bin/sh

if [ -z ${SSH_HOST+x} ]; then
  SSH_HOST=$(/sbin/ip route | awk '/default/ { print $3 }')
fi
if [ -z ${SSH_USER+x} ]; then
  SSH_USER="root"
fi
ssh-keyscan -H $SSH_HOST > ~/.ssh/known_hosts


if [ -z ${TOMCAT_SSL_ENABLED+x} ]; then
  cp -f /usr/local/tomcat/webapps/ROOT/WEB-INF/web_http.xml /usr/local/tomcat/webapps/ROOT/WEB-INF/web.xml
else
  cp -f /usr/local/tomcat/webapps/ROOT/WEB-INF/web_https.xml /usr/local/tomcat/webapps/ROOT/WEB-INF/web.xml
fi


cat << EOF > /bin/lxc-attach
#!/bin/sh
ssh $SSH_USER@$SSH_HOST lxc-attach \$(printf "\\"%s\\" " "\$@")
EOF


cat << EOF > /usr/local/tomcat/webapps/ROOT/META-INF/context.xml
<?xml version="1.0" encoding="utf-8"?>
<Context docBase="ZeroJudge">
	<!-- <Valve className="org.apache.catalina.valves.RemoteAddrValve" allow="*" deny="192.168.22.33" /> -->
	<Resource auth="Container" driverClassName="com.mysql.jdbc.Driver" logAbandoned="true" maxTotal="50" maxIdle="50" maxWaitMillis="10000" name="mysql" password="$MY_SQL_PASSWORD" removeAbandonedOnBorrow="true" removeAbandonedOnMaintenance="true" removeAbandonedTimeout="60" type="javax.sql.DataSource" url="jdbc:mysql://$MY_SQL_IP:$MY_SQL_PORT/$MY_SQL_DB_NAME?useUnicode=true&amp;characterEncoding=UTF-8&amp;useSSL=false" username="$MY_SQL_USERNAME" />
	<!-- session 持久化，存入資料庫 -->
	<Manager className="org.apache.catalina.session.PersistentManager" maxIdleBackup="10" saveOnRestart="true">
		<Store className="org.apache.catalina.session.JDBCStore" connectionName="$MY_SQL_USERNAME" connectionPassword="$MY_SQL_PASSWORD" connectionURL="jdbc:mysql://$MY_SQL_IP:$MY_SQL_PORT/$MY_SQL_DB_NAME?useUnicode=true&amp;characterEncoding=UTF-8&amp;useSSL=false" driverName="com.mysql.jdbc.Driver" sessionAppCol="app_name" sessionDataCol="session_data" sessionIdCol="session_id" sessionLastAccessedCol="last_access" sessionMaxInactiveCol="max_inactive" sessionTable="tomcat_sessions" sessionValidCol="valid_session" />
	</Manager>
EOF

if [ ! -z ${REVERSE_PROXY_IP+x} ]; then
cat << EOF >> /usr/local/tomcat/webapps/ROOT/META-INF/context.xml
    <Valve className="org.apache.catalina.valves.RemoteIpValve" internalProxies="$(printf '%s' "${REVERSE_PROXY_IP//./\\.}")" remoteIpHeader="x-forwarded-for" proxiesHeader="x-forwarded-by" trustedProxies="$REVERSE_PROXY_IP" />
EOF
fi

cat << EOF >> /usr/local/tomcat/webapps/ROOT/META-INF/context.xml
	<!-- session 持久化，存入檔案 -->
	<!-- <Manager className="org.apache.catalina.session.PersistentManager" saveOnRestart="true"><Store className="org.apache.catalina.session.FileStore" /></Manager> -->
</Context>
EOF


cat << EOF > /usr/local/tomcat/webapps/ZeroJudge_Server/META-INF/context.xml
<?xml version="1.0" encoding="UTF-8"?>
<Context docBase="ZeroJudge_Server">
	<!-- <Valve className="org.apache.catalina.valves.RemoteAddrValve" allow="127.0.0.1|163.32.92.12|163.32.92.3" /> -->
EOF

if [ ! -z ${REVERSE_PROXY_IP+x} ]; then
cat << EOF >> /usr/local/tomcat/webapps/ZeroJudge_Server/META-INF/context.xml
    <Valve className="org.apache.catalina.valves.RemoteIpValve" internalProxies="$(printf "${REVERSE_PROXY_IP//./\\.}")" remoteIpHeader="x-forwarded-for" proxiesHeader="x-forwarded-by" trustedProxies="$REVERSE_PROXY_IP" />
EOF
fi

cat << EOF >> /usr/local/tomcat/webapps/ZeroJudge_Server/META-INF/context.xml
</Context>
EOF


chmod 755 /bin/lxc-attach

echo > /usr/local/tomcat/webapps/ROOT/InitializedListener.py
chown -R zero:zero /ZeroJudge_CONSOLE
chmod -R 770 /ZeroJudge_CONSOLE


echo > /usr/local/tomcat/webapps/ZeroJudge_Server/InitializedListener.py
chown -R zero:zero 
chmod -R 770 /JudgeServer_CONSOLE


exec /usr/local/tomcat/bin/catalina.sh run
