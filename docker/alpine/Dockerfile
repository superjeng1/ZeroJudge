FROM docker.io/tomcat@sha256:2a80998e2d5b8c5c283be09b0bf384278e603a23d14aacb8772799305ee6a168 AS builder
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


FROM docker.io/alpine@sha256:234cb88d3020898631af0ccbbcca9a66ae7306ecd30c9720690858c1b007d2a0 AS deployer
# The above is checksum of docker.io/alpine:latest and will be automatically updated by GitHub actions

ENV TOMCAT_MAJOR=9 \
    TOMCAT_VERSION=9.0.48 \
    TOMCAT_SHA512=9fcde76bc192c5b02b467c7fc01727ec7c72acfc207741b03a582c67565218dd9b6ea9b9cf007b5964e7794f271433f66e3452b33352b9b657cd7e2bfff08f02 \
    GPG_KEY_FILE_SHA512=f333a7bc1a1ef6762f0b9193d1e3e669d7628ee1613b884200b4e9a091eb813c8c4eb9491f13580c14df1a1ecba94b2a1c0b98ed35a7302c6fb800390906a19f \
    # The checksum in the above line is a SHA512 checksum of this file: https://www.apache.org/dist/tomcat/tomcat-$TOMCAT_MAJOR/KEYS
    CATALINA_HOME=/usr/local/tomcat \
    CATALINA_OUT=/dev/null \
    TOMCAT_HOME=/usr/local/tomcat \
    JAVA_HOME=/usr/lib/jvm/java-1.8-openjdk/jre \
    PATH="/usr/local/tomcat/bin:$PATH"

COPY --from=builder /build/wars /usr/local/tomcat/webapps/
COPY scripts/zerojudge-init.sh /usr/local/tomcat/bin/zerojudge-init.sh

RUN mkdir -p "$CATALINA_HOME" && \
    cd "$CATALINA_HOME" && \
    apk add --no-cache gnupg wget openjdk8-jre && \
    ddist() { \
        local f="$1"; shift; \
        local distFile="$1"; shift; \
        local mvnFile="${1:-}"; \
        local success=; \
        local distUrl=; \
        for distUrl in \
            "https://www.apache.org/dyn/closer.cgi?action=download&filename=$distFile" \
            "https://www-us.apache.org/dist/$distFile" \
            "https://www.apache.org/dist/$distFile" \
            "https://archive.apache.org/dist/$distFile" \
            ${mvnFile:+"https://repo1.maven.org/maven2/org/apache/tomcat/tomcat/$mvnFile"} \
        ; do \
            if wget -nv -O "$f" "$distUrl" && [ -s "$f" ]; then \
                success=1; \
                break; \
            fi; \
        done; \
        [ -n "$success" ]; \
    } && \
    \
    ddist 'tomcat.tar.gz' "tomcat/tomcat-$TOMCAT_MAJOR/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz" "$TOMCAT_VERSION/tomcat-$TOMCAT_VERSION.tar.gz" && \
    echo "$TOMCAT_SHA512  tomcat.tar.gz" | sha512sum -c - && \
    wget -nv -O "tomcat.tar.gz.asc" "https://downloads.apache.org/tomcat/tomcat-$TOMCAT_MAJOR/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz.asc" && [ -s "tomcat.tar.gz.asc" ] && \
    wget -nv -O "KEYS" "https://downloads.apache.org/tomcat/tomcat-$TOMCAT_MAJOR/KEYS" && [ -s "KEYS" ] && \
    echo "$GPG_KEY_FILE_SHA512  KEYS" | sha512sum -c - && \
    export GNUPGHOME="$(mktemp -d)" && \
    gpg --batch --import < KEYS && \
    gpg --list-keys --fingerprint | grep pub -A 1 | egrep -Ev "pub|--" | tr -d ' '  | awk 'BEGIN { FS = "\n" } ; { print $1":6:" } ' | gpg --batch --import-ownertrust && \
    gpg --batch --verify tomcat.tar.gz.asc tomcat.tar.gz && \
    tar -xf tomcat.tar.gz --strip-components=1 --exclude="apache-tomcat-*/webapps" && \
    rm bin/*.bat && \
    rm tomcat.tar.gz* && \
    wget -nv -O lib/mysql-connector-java-5.1.6.jar https://repo1.maven.org/maven2/mysql/mysql-connector-java/5.1.6/mysql-connector-java-5.1.6.jar && \
    catalina.sh start && \
    until $(nc -z 127.0.0.1 8005); do sleep 1; done && \
    catalina.sh stop && \
    rm webapps/*.war


FROM docker.io/alpine@sha256:234cb88d3020898631af0ccbbcca9a66ae7306ecd30c9720690858c1b007d2a0
# The above is checksum of docker.io/alpine:latest and will be automatically updated by GitHub actions

ENV TOMCAT_MAJOR=9 \
    TOMCAT_VERSION=9.0.48 \
    TOMCAT_SHA512=9fcde76bc192c5b02b467c7fc01727ec7c72acfc207741b03a582c67565218dd9b6ea9b9cf007b5964e7794f271433f66e3452b33352b9b657cd7e2bfff08f02 \
    GPG_KEY_FILE_SHA512=f333a7bc1a1ef6762f0b9193d1e3e669d7628ee1613b884200b4e9a091eb813c8c4eb9491f13580c14df1a1ecba94b2a1c0b98ed35a7302c6fb800390906a19f \
    # The checksum in the above line is a SHA512 checksum of this file: https://www.apache.org/dist/tomcat/tomcat-$TOMCAT_MAJOR/KEYS
    CATALINA_HOME=/usr/local/tomcat \
    CATALINA_OUT=/dev/null \
    TOMCAT_HOME=/usr/local/tomcat \
    JAVA_HOME=/usr/lib/jvm/java-1.8-openjdk/jre \
    PATH="/usr/local/tomcat/bin:$PATH"

COPY --from=deployer /usr/local/tomcat /usr/local/tomcat
COPY --from=builder /JudgeServer_CONSOLE /JudgeServer_CONSOLE

WORKDIR $CATALINA_HOME

RUN addgroup -Sg 1000 zero && \
    adduser -SDHG zero -u 1000 zero && \
    apk add --no-cache openjdk8-jre sudo openssh-client dos2unix rsync python3 && \
    mkdir /etc/zerojudge && \
    ln -sf /etc/zerojudge/ssh /root/.ssh && \
    ln -sf /etc/zerojudge/configs/ServerConfig.xml /usr/local/tomcat/webapps/ZeroJudge_Server/WEB-INF/ServerConfig.xml && \
    ln -sf /etc/zerojudge/disk/ZeroJudge_CONSOLE /ZeroJudge_CONSOLE && \
    chmod 755 /usr/local/tomcat/bin/zerojudge-init.sh

VOLUME [ "/etc/zerojudge", "/var/lib/lxc/lxc-ALL" ]

EXPOSE 8080

CMD [ "zerojudge-init.sh" ]
