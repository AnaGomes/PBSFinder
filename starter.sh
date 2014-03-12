#!/bin/bash --login
[ -s "$HOME/.rvm/scripts/rvm" ] && . "$HOME/.rvm/scripts/rvm"

HOST="localhost"

echo -e "Killing remaining processes...\n"
PID=$(ps -elf | grep -E "padrino|master_worker" | grep -v grep | awk '{ print $4; }')
mapfile -t PIDS <<< "$PID"
PID1=${PIDS[0]}
PID2=${PIDS[1]}
kill -kill "${PID1} ${PID2}"

echo -e "Starting worker server...\n"
cd ./worker_server
rvm use 2.1.1@pbsworker
nohup ruby master_worker.rb &

echo -e "Starting web app...\n"
cd ../webapp
rvm use 2.1.1@pbssite
padrino start -h "$HOST" -d

echo -e "Done."
