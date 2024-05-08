FROM maven:3.9.6-eclipse-temurin-17 as builder-17

RUN apt update \
    && apt install -y git \
    && rm -rf /var/lib/apt/lists/*


FROM builder-17 as benchmark

RUN git clone --depth 1 --branch main https://github.com/OWASP-Benchmark/BenchmarkUtils \
    && cd BenchmarkUtils \
    && mvn install -Dmaven.test.skip -Dspotless.apply.skip

RUN git clone --depth 1 --branch master https://github.com/OWASP-Benchmark/BenchmarkJava -b master \
    && cd BenchmarkJava \
    && mvn initialize \
    && mvn clean package cargo:start -Pdeploy -Dmaven.test.skip -Dspotless.apply.skip

RUN rm -rf /BenchmarkJava/results/*

RUN sed -i.bak 's|</cargo.start.jvmargs>|</cargo.start.jvmargs><cargo.jvmargs>-Xms2G -Xmx8G -javaagent:\${env.JAVA_AGENT} -Ddd.trace.debug=true -Ddd.iast.enabled=true -Ddd.iast.detection.mode=FULL -Ddatadog.slf4j.simpleLogger.defaultLogLevel=debug -Ddatadog.slf4j.simpleLogger.logFile=\${env.OUTPUT_FOLDER}/benchmark/dd-java-tracer.log</cargo.jvmargs>|g' /BenchmarkJava/pom.xml


FROM gradle:8.7.0-jdk17 as insecure-bank

RUN mkdir /app \
    && cd /app \
    && git clone --depth 1 --branch malvarez/spring-boot https://github.com/hdiv/insecure-bank.git \
    && cd insecure-bank \
    && gradle bootWar


FROM builder-17 as webgoat

RUN git clone --depth 1 --branch main https://github.com/WebGoat/WebGoat.git \
    && cd WebGoat \
    && mvn install -Dmaven.test.skip


FROM builder-17

RUN apt update \
    && apt install -y nginx \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir /apps \
    && mkdir /apps/benchmark \
    && mkdir /apps/insecure-bank \
    && mkdir /apps/webgoat

RUN mkdir /out

RUN mkdir /agent

COPY --from=benchmark /BenchmarkJava /apps/benchmark
COPY --from=benchmark /root/.m2 /root/.m2
COPY --from=insecure-bank /app/insecure-bank/build/libs/insecure-bank-*.war /apps/insecure-bank/insecure-bank.war
COPY --from=webgoat /WebGoat/target/webgoat*.jar /apps/webgoat/webgoat.jar

ENV WEBGOAT_HOST=0.0.0.0
ENV WEBGOAT_PORT=8080

ENV WEBWOLF_HOST=0.0.0.0
ENV WEBWOLF_PORT=9090

ENV INSECURE_BANK_HOST=0.0.0.0
ENV INSECURE_BANK_PORT=8080

ENV JAVA_AGENT=/agent/dd-java-agent.jar

ENV OUTPUT_FOLDER=/out

ADD entrypoint.sh /entrypoint.sh

ADD nginx.conf /etc/nginx/sites-available/default

ENTRYPOINT ["/entrypoint.sh"]
