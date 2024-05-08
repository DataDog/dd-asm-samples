# Datadog ASM sample applications

This repository contains the necessary resources to evaluate Datadog's code security products in the Java ecosystem.
There are three applications available:

* [Insecure bank](https://github.com/hdiv/insecure-bank) purposely vulnerable banking application where you can find 
multiple issues like SQLi, LDAPi and others.

* [OWASP benchmark](https://owasp.org/www-project-benchmark/) Java test suite designed to evaluate the accuracy,
coverage, and speed of automated software vulnerability detection tools.
 
* [OWASP WebGoat](https://owasp.org/www-project-webgoat/) deliberately insecure application that allows interested 
developers just like you to test vulnerabilities commonly found in Java-based applications that use common and popular 
open source components.

## Prerequisites

The only requirements for the samples are [docker](https://www.docker.com/) and 
[docker-compose](https://docs.docker.com/compose/).

You will also need a valid [Datadog API key](https://docs.datadoghq.com/account_management/api-app-keys/) in order to 
submit the discovered vulnerabilities (rename the provided `.env.sample` file as `.env` and copy your API key).

By default, the samples will download the latest release of the java tracer from this
[link](https://github.com/DataDog/dd-trace-java/releases/download/download-latest/dd-java-agent.jar), you can override 
this behaviour by mounting your own jar inside the `docker-compose.yml` file:

```yaml
volumes:
  - path to your agent here:/agent/dd-java-agent.jar
```

## Instructions
This repository provides a shell script `run.sh` that can be used to start, stop and inspect the logs from the different
containers:

1. **start** starts one of the provided applications

```shell
./run.sh start [insecure-bank|webgoat|benchmark]
```

2. **logs** outputs the logs of the containers

```shell
./run.sh logs
```

3. **stop** stops the running application

```shell
./run.sh stop
```


## Running the samples

### Insecure Bank
Insecure bank can be started with the following shell command:

```shell
./run.sh start insecure-bank
```

After a few minutes the application will be available at http://localhost:8080 and the logs at 
http://localhost:8181/insecure-bank/, you can start navigating the application in order to discover the different
available vulnerabilities. 

For example, you can try to log-in using:
* username: **john**
* password: **test**

And you will have SQLi and LDAPi vulnerabilities available at Datadog (application `dd-asm-samples-insecure-bank`)

You can stop the application by running:

```shell
./run.sh stop
```

### Benchmark
The OWASP benchmark can be executed with the following command:

```shell
./run.sh start benchmark
```

After a few minutes the benchmark will have finished and the scorecards will be available at 
http://localhost:8181/scorecard/. 

You will have all the vulnerabilities at Datadog (application `dd-asm-samples-benchmark`)

You can stop the application by running:

```shell
./run.sh stop
```

### WebGoat
WebGoat can be started with the following shell command:

```shell
./run.sh start webgoat
```

After a few minutes the application will be available at http://localhost:8080/WebGoat and the logs at
http://localhost:8181/webgoat/, follow the different lessons in order to trigger vulnerabilities.

For example, you can use lesson 5 of SQLi to trigger the vulnerability:


You will have SQLi vulnerability available at Datadog (application `dd-asm-samples-webgoat`)

You can stop the application by running:

```shell
./run.sh stop
```