FROM docker.io/tomcat@sha256:76bbdb8243ec4de4074b6c0ad03921cfbb39a717a9ab80fbfc894da92b41798e AS builder
# The above is checksum of docker.io/tomcat:9-jdk8-openjdk-slim and will be automatically updated by GitHub actions

RUN apt-get update && \
    mkdir -p /usr/share/man/man1 && \
    apt-get install --no-install-recommends ant git python3 sudo g++ curl -y && \
    mkdir /build && \
    git clone https://github.com/jiangsir/ZeroJudge.git /build/ZeroJudge && \
    git --git-dir=/build/ZeroJudge/.git --work-tree=/build/ZeroJudge checkout -b branch_3.3 3.3 && \
    git clone https://github.com/jiangsir/ZeroJudge_Server.git /build/ZeroJudge_Server && \
    git --git-dir=/build/ZeroJudge_Server/.git --work-tree=/build/ZeroJudge_Server checkout -b branch_3.3 3.3 && \
    printf '3.3' > /build/ZeroJudge/WebContent/META-INF/Version.txt && \
    printf '3.3' > /build/ZeroJudge_Server/WebContent/META-INF/Version.txt && \
    printf 'import os\napptmpdir = "/build/ZeroJudge"\nfor root, dirs, files in os.walk(apptmpdir + "/src/"):\n  for file in files:\n    if file.endswith(".java"):\n      print(os.path.join(root, file))\n      s = open(os.path.join(root, file), mode="r",\n        encoding="utf-8-sig").read()\n      open(os.path.join(root, file), mode="w",\n        encoding="utf-8").write(s)' | python3 && \
    ant -f /build/ZeroJudge/build.xml clean makewar callpy -Dappname=ROOT -DTOMCAT_HOME=/usr/local/tomcat/ && \
    ant -f /build/ZeroJudge_Server/build.xml move_CONSOLE makewar -Dappname=ZeroJudge_Server -DTOMCAT_HOME=/usr/local/tomcat/ && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir /build/wars && \
    mv /build/ZeroJudge/ROOT.war /build/wars && \
    mv /build/ZeroJudge_Server/ZeroJudge_Server.war /build/wars


FROM docker.io/tomcat@sha256:76bbdb8243ec4de4074b6c0ad03921cfbb39a717a9ab80fbfc894da92b41798e AS deployer
# The above is checksum of docker.io/tomcat:9-jdk8-openjdk-slim and will be automatically updated by GitHub actions

ENV SHEBANG="#!/bin/bash"

COPY --from=builder /build/wars /usr/local/tomcat/webapps/
COPY scripts/zerojudge-init.sh /tmp

RUN apt-get update && \
    apt-get install --no-install-recommends curl netcat -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    curl https://repo1.maven.org/maven2/mysql/mysql-connector-java/5.1.6/mysql-connector-java-5.1.6.jar -o /usr/local/tomcat/lib/mysql-connector-java-5.1.6.jar && \
    catalina.sh start && \
    until $(nc -z 127.0.0.1 8005); do sleep 1; done && \
    catalina.sh stop && \
    rm /usr/local/tomcat/webapps/*.war && \
    printf '%s\n%s\n' "${SHEBANG}" "SHEBANG=\"${SHEBANG}\"" > /usr/local/tomcat/bin/zerojudge-init.sh && \
    tail +3 /tmp/zerojudge-init.sh >> /usr/local/tomcat/bin/zerojudge-init.sh


FROM docker.io/tomcat@sha256:76bbdb8243ec4de4074b6c0ad03921cfbb39a717a9ab80fbfc894da92b41798e
# The above is checksum of docker.io/tomcat:9-jdk8-openjdk-slim and will be automatically updated by GitHub actions

COPY --from=deployer /usr/local/tomcat /usr/local/tomcat
COPY --from=builder /JudgeServer_CONSOLE /JudgeServer_CONSOLE

RUN groupadd -rg 1000 zero && \
    useradd -rs /usr/sbin/nologin -u 1000 -g 1000 zero && \
    apt-get update && \
    apt-get install --no-install-recommends sudo ssh dos2unix rsync python3-bs4 iproute2 -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir /etc/zerojudge && \
    ln -sf /etc/zerojudge/ssh /root/.ssh && \
    ln -sf /etc/zerojudge/configs/ServerConfig.xml /usr/local/tomcat/webapps/ZeroJudge_Server/WEB-INF/ServerConfig.xml && \
    ln -sf /etc/zerojudge/disk/ZeroJudge_CONSOLE /ZeroJudge_CONSOLE && \
    chmod 755 /usr/local/tomcat/bin/zerojudge-init.sh

VOLUME [ "/etc/zerojudge", "/var/lib/lxc/lxc-ALL" ]

EXPOSE 8080

CMD [ "/bin/bash", "zerojudge-init.sh" ]
