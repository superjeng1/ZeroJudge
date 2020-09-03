FROM docker.io/tomcat:8-jdk8-openjdk-slim AS builder

RUN apt-get update && \
    mkdir -p /usr/share/man/man1 && \
    apt-get install --no-install-recommends ant git python3 sudo g++ wget -y && \
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
    mv /build/ZeroJudge/ZeroJudge_CONSOLE/ / && \
    find /ZeroJudge_CONSOLE -type d -exec chmod 770 {} \; && \
    chmod -R g+rw /ZeroJudge_CONSOLE/Testdata/ && \
    chmod -R g+rw /ZeroJudge_CONSOLE/Special/ && \
    wget https://repo1.maven.org/maven2/mysql/mysql-connector-java/5.1.6/mysql-connector-java-5.1.6.jar -P /build && \
    apt-get clean && \
    rm -rf /var/cache/apt/lists

FROM docker.io/tomcat:8-jdk8-openjdk-slim

RUN useradd -u 1002 zero && \
    apt-get update && \
    apt-get install --no-install-recommends sudo ssh dos2unix rsync python3-bs4 -y && \
    apt-get clean && \
    rm -rf /var/cache/apt/lists

COPY --from=builder /build/ZeroJudge/ROOT.war /usr/local/tomcat/webapps
COPY --from=builder /build/ZeroJudge_Server/ZeroJudge_Server.war /usr/local/tomcat/webapps
COPY --from=builder /build/mysql-connector-java-5.1.6.jar /usr/local/tomcat/lib
COPY --from=builder /ZeroJudge_CONSOLE /ZeroJudge_CONSOLE
COPY --from=builder /JudgeServer_CONSOLE /JudgeServer_CONSOLE

#COPY /container-zerojudge-data/ssh/id_rsa /root/.ssh/id_rsa
#COPY /container-zerojudge-data/ssh/id_rsa.pub /root/.ssh/id_rsa.pub
#COPY /container-zerojudge-data/ssh/known_hosts /root/.ssh/known_hosts

COPY lxc-attach /bin/lxc-attach

CMD ["catalina.sh", "run"]
