FROM docker.io/tomcat:9-jdk8-openjdk-slim AS builder

RUN apt-get update && \
    mkdir -p /usr/share/man/man1 && \
    apt-get install --no-install-recommends ant git python3 sudo g++ curl -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir /build && \
    git clone https://github.com/jiangsir/ZeroJudge.git /build/ZeroJudge && \
    git --git-dir=/build/ZeroJudge/.git --work-tree=/build/ZeroJudge checkout -b branch_3.3 3.3 && \
    git clone https://github.com/jiangsir/ZeroJudge_Server.git /build/ZeroJudge_Server && \
    git --git-dir=/build/ZeroJudge_Server/.git --work-tree=/build/ZeroJudge_Server checkout -b branch_3.3 3.3 && \
    printf '3.3' > /build/ZeroJudge/WebContent/META-INF/Version.txt && \
    printf '3.3' > /build/ZeroJudge_Server/WebContent/META-INF/Version.txt && \
    printf 'import os\napptmpdir = "/build/ZeroJudge"\nfor root, dirs, files in os.walk(apptmpdir + "/src/"):\n  for file in files:\n    if file.endswith(".java"):\n      print(os.path.join(root, file))\n      s = open(os.path.join(root, file), mode="r",\n        encoding="utf-8-sig").read()\n      open(os.path.join(root, file), mode="w",\n        encoding="utf-8").write(s)' | python3

RUN ant -f /build/ZeroJudge/build.xml clean makewar callpy -Dappname=ROOT -DTOMCAT_HOME=/usr/local/tomcat/ && \
    ant -f /build/ZeroJudge_Server/build.xml move_CONSOLE makewar -Dappname=ZeroJudge_Server -DTOMCAT_HOME=/usr/local/tomcat/ && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir /build/wars && \
    mv /build/ZeroJudge/ROOT.war /build/wars && \
    mv /build/ZeroJudge_Server/ZeroJudge_Server.war /build/wars


FROM docker.io/alpine:latest AS deployer

ENV TOMCAT_MAJOR=9 \
    TOMCAT_VERSION=9.0.37 \
    TOMCAT_SHA512=077c3e69553b9388b5cdf46b6d204e895d69629a4ec8dd8cf13eb2ee97a04f50e70478fee4f2f91e8809b85bdcd3656188b00d17165c86cf6113ded18729ba06 \
    TOMCAT_HOME=/usr/local/tomcat \
    TOMCAT_NATIVE_LIBDIR=/usr/local/tomcat/native-jni-lib \
    LD_LIBRARY_PATH=/usr/local/tomcat/native-jni-lib \
    CATALINA_HOME=/usr/local/tomcat \
    CATALINA_OUT=/dev/null \
    JAVA_HOME=/usr/lib/jvm/java-1.8-openjdk/jre \
    PATH=$PATH:/usr/lib/jvm/java-1.8-openjdk/jre/bin:/usr/lib/jvm/java-1.8-openjdk/bin:/usr/local/tomcat/bin

ENV GPG_KEYS 05AB33110949707C93A279E3D3EFE6B686867BA6 07E48665A34DCAFAE522E5E6266191C37C037D42 47309207D818FFD8DCD3F83F1931D684307A10A5 541FBE7D8F78B25E055DDEE13C370389288584E7 61B832AC2F1C5A90F0F9B00A1C506407564C17A3 79F7026C690BAA50B92CD8B66A3AD3F4F22C4FED 9BA44C2621385CB966EBA586F72C284D731FABEE A27677289986DB50844682F8ACB77FC2E86E29AC A9C5DF4D22E99998D9875A5110C01C5A2F6059E7 DCFD35E0BF8CA7344752DE8B6FB21E8933C60243 F3A04C595DB5B6A5F1ECA43E3B7BBB100D811BBE F7DA48BB64BCB84ECBA7EE6935CD23C10D498E23

RUN mkdir -p "$CATALINA_HOME"
WORKDIR $CATALINA_HOME

RUN apk add --no-cache gnupg wget openjdk8-jre && \
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
    echo "$TOMCAT_SHA512 *tomcat.tar.gz" | sha512sum -c - && \
    ddist 'tomcat.tar.gz.asc' "tomcat/tomcat-$TOMCAT_MAJOR/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz.asc" "$TOMCAT_VERSION/tomcat-$TOMCAT_VERSION.tar.gz.asc" && \
    export GNUPGHOME="$(mktemp -d)" && \
    for key in $GPG_KEYS; do \
        gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
    done && \
    gpg --batch --verify tomcat.tar.gz.asc tomcat.tar.gz && \
    tar -xf tomcat.tar.gz --strip-components=1 && \
    rm bin/*.bat && \
    rm tomcat.tar.gz* && \
    command -v gpgconf && gpgconf --kill all || : && \
    rm -rf webapps/* && \
    wget -nv -O lib/mysql-connector-java-5.1.6.jar https://repo1.maven.org/maven2/mysql/mysql-connector-java/5.1.6/mysql-connector-java-5.1.6.jar

COPY --from=builder /build/wars /usr/local/tomcat/webapps/
COPY scripts/zerojudge-init.sh /usr/local/tomcat/bin

RUN catalina.sh start && \
    until $(nc -z 127.0.0.1 8005); do sleep 1; done && \
    catalina.sh stop && \
    rm webapps/*.war


FROM docker.io/alpine:latest

ENV TOMCAT_MAJOR=9 \
    TOMCAT_VERSION=9.0.37 \
    TOMCAT_HOME=/usr/local/tomcat \
    CATALINA_HOME=/usr/local/tomcat \
    CATALINA_OUT=/dev/null \
    JAVA_HOME=/usr/lib/jvm/java-1.8-openjdk/jre \
    PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/lib/jvm/java-1.8-openjdk/jre/bin:/usr/lib/jvm/java-1.8-openjdk/bin:/usr/local/tomcat/bin

COPY --from=deployer /usr/local/tomcat /usr/local/tomcat
COPY --from=builder /JudgeServer_CONSOLE /JudgeServer_CONSOLE

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