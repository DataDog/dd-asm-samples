#!/bin/bash

set -eu

tests=(webgoat benchmark insecure-bank)
basedir=$(dirname "$0")

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
  print "INFO" "$app: Waiting for application to be ready at $url"
  curl --silent --no-progress-meter --insecure --fail --head -X GET --retry 24 --retry-all-errors --retry-delay 5 "$url" >/dev/null
  print "INFO" "$app: Ready at $url"
}

run_web_goat() {
  print "INFO" "WebGoat: Starting application"
  docker-compose up -d datadog-agent webgoat
  wait_for "WebGoat" "http://localhost:8080/WebGoat"
  print "INFO" "WebGoat: Logs are available at http://localhost:8181/webgoat/"
  print "INFO" "WebGoat: Start navigating the application and watch for vulnerabilities at Datadog"
}

run_benchmark() {
  print "INFO" "Benchmark: Starting application"
  docker-compose up -d datadog-agent benchmark
  wait_for "Benchmark" "http://localhost:8181/scorecard/"
  print "INFO" "Benchmark: Logs are available at http://localhost:8181/benchmark/"
  print "INFO" "Benchmark: Scorecards are available at http://localhost:8181/scorecard/"
  print "INFO" "Benchmark: Vulnerabilities should be available at Datadog"
}

run_insecure_bank() {
  print "INFO" "Insecure Bank: Starting application"
  docker-compose up -d datadog-agent insecure-bank
  wait_for "Insecure Bank" "http://localhost:8080"
  print "INFO" "Insecure Bank: Logs are available at http://localhost:8181/insecure-bank/"
  print "INFO" "Insecure Bank: Start navigating the application and watch for vulnerabilities at Datadog"
}

start() {
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
}

stop() {
  docker-compose down
}

logs() {
  docker-compose logs -f
}

command -v docker-compose >/dev/null 2>&1 || {
  print "ERROR" "Please install docker-compose before running the samples.";
  exit 1
}

if ! [ -f "$basedir/.env" ]; then
   print "ERROR" "Missing .env file, create a new one with the following contents:"
   echo "DD_API_KEY=(Required) your API key here"
   exit 1
fi

if [ $# -lt 1 ]; then
  print "ERROR" "Choose one of the available commands: start, stop, logs"
  exit 1
fi

case $1 in
  "start")
    start "$2"
    ;;
  "stop")
    stop
    ;;
  "logs")
    logs
    ;;
  *)
    print "ERROR" "Invalid command '$1' chose one of: start, stop, logs"
    exit 1
    ;;
esac

exit 0