#!/bin/bash

set -eu

tests=(webgoat benchmark insecure-bank)

apps_folder="/apps"
webgoat="$apps_folder/webgoat/webgoat.jar"
insecure_bank="$apps_folder/insecure-bank/insecure-bank.war"
benchmark="$apps_folder/benchmark"

print() {
  level=$1
  message=$2
  message="[$level] $message"
  if [ "$level" = "ERROR" ]; then
    >&2 echo "$message"
  else
    echo "$message"
  fi
}

wait_for() {
  app=$1
  url=$2
  print "INFO" "($app) Waiting for server to be ready at $url"
  curl --silent --no-progress-meter --insecure --fail --head -X GET --retry 24 --retry-all-errors --retry-delay 5 "$url" >/dev/null
  print "INFO" "($app) Ready at $url"
}

download_agent() {
  if ! [ -f "$JAVA_AGENT" ]; then
    print "INFO" "Agent not found, downloading last release"
    wget --quiet https://github.com/DataDog/dd-trace-java/releases/download/download-latest/dd-java-agent.jar -O "$JAVA_AGENT"
  fi
}

run_nginx() {
  print "INFO" "Starting NGINX background server"
  nginx &
}

run_web_goat() {
  download_agent
  run_nginx
  mkdir -p "$OUTPUT_FOLDER/webgoat"
  java "-javaagent:$JAVA_AGENT" -jar "$webgoat" 2>&1 | tee "$OUTPUT_FOLDER/webgoat/webgoat.log"
}

run_benchmark() {
  download_agent
  run_nginx
  cd "$benchmark"
  mkdir -p "$OUTPUT_FOLDER/benchmark"
  mvn initialize 2>&1 | tee "$OUTPUT_FOLDER/benchmark/mvn.log"
  mvn package cargo:run -Dspotless.apply.skip -Pdeploy 2>&1 | tee -a "$OUTPUT_FOLDER/benchmark/mvn.log" &
  java_proces=$!
  wait_for "OWASP benchmark" "https://localhost:8443/benchmark/"
  print "INFO" "(OWASP benchmark) Crawling application"
  mvn org.owasp:benchmarkutils-maven-plugin:run-crawler -DcrawlerFile=data/benchmark-crawler-http.xml 2>&1 | tee -a "$OUTPUT_FOLDER/benchmark/mvn.log"  &
  wait "$!"
  cp "${OUTPUT_FOLDER}/benchmark/dd-java-tracer.log" /apps/benchmark/results/dd-agent-log.log
  print "INFO" "(OWASP benchmark) Building scorecards"
  MAVEN_OPTS="-Xmx8G" mvn -Djava.awt.headless=true org.owasp:benchmarkutils-maven-plugin:create-scorecard 2>&1 | tee -a "$OUTPUT_FOLDER/benchmark/mvn.log" &
  wait "$!"
  cp -r /apps/benchmark/target/log/* "$OUTPUT_FOLDER/benchmark/"
  mkdir -p "$OUTPUT_FOLDER/scorecard"
  cp -r /apps/benchmark/scorecard/* "$OUTPUT_FOLDER/scorecard/"
  print "INFO" "(OWASP benchmark) Scorecards should be available in your output folder"
  wait "$java_proces"
}

run_insecure_bank() {
  download_agent
  run_nginx
  mkdir -p "$OUTPUT_FOLDER/insecure-bank"
  java "-javaagent:$JAVA_AGENT" -jar "$insecure_bank" 2>&1 | tee "$OUTPUT_FOLDER/insecure-bank/insecure-bank.log"
}

if [ $# -lt 1 ]; then
  print "ERROR" "Choose one of the available samples: ${tests[*]}"
  exit 1
fi

case $1 in
  "${tests[0]}")
    run_web_goat
    ;;
  "${tests[1]}")
    run_benchmark
    ;;
  "${tests[2]}")
    run_insecure_bank
    ;;
  *)
    print "ERROR" "Invalid sample '$1' chose one of: ${tests[*]}"
    exit 1
    ;;
esac

exit 0
