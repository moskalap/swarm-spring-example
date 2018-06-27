#!/bin/bash
#utworzenie managerów i workerów w swarmie na localhoscie
# default parameters
DRIVER="virtualbox"
MANAGERS=1 #przewa¿nie jeden manager, loguj¹c siê przez ssh do niego mo¿na zarz¹dzaæ ca³ym klastrem
WORKERS=3 
DISK_SIZE="20000"
MEMORY="2048" 
DOCKER_VERSION="https://github.com/boot2docker/boot2docker/releases/download/v1.13.0/boot2docker.iso"
ADDITIONAL_PARAMS=


if [ "$DRIVER" == "virtualbox" ]; then
  echo "-> about to create a swarm with $MANAGERS manager(s) and $WORKERS WORKERS on $DRIVER machines"
  ADDITIONAL_PARAMS="--virtualbox-disk-size ${DISK_SIZE} --virtualbox-memory ${MEMORY} --virtualbox-boot2docker-url=${DOCKER_VERSION}"
  #mo¿na dodaæ case dla pozosta³ych driverów
fi

function getIP {
  echo $(docker-machine ip $1)
}

function get_worker_token {
  echo $(docker-machine ssh manager1 docker swarm join-token worker -q)
}

function createManagerNode {
  for i in $(seq 1 $MANAGERS);
  do
    echo "== Creating manager$i machine ...";
    docker-machine create -d $DRIVER $ADDITIONAL_PARAMS manager$i

  done
}

function createWorkerNode {
  # create worker machines
  for i in $(seq 1 $WORKERS);
  do
    echo "== Creating worker$i machine ...";
    docker-machine create -d $DRIVER $ADDITIONAL_PARAMS worker$i
  done
}

function initSwarmManager {
  # initialize swarm mode and create a manager
  echo '============================================'
  echo "======> Initializing first swarm manager ..."
  docker-machine ssh manager1 docker swarm init --listen-addr $(getIP manager1):2376 --advertise-addr $(getIP manager1):2376
}

function join_node_swarm {
  # WORKERS join swarm
  for node in $(seq 1 $WORKERS);
  do
    echo "======> worker$node joining swarm as worker ..."
    docker-machine ssh worker$node docker swarm join --token $(get_worker_token) --listen-addr $(getIP worker$node):2376 --advertise-addr $(getIP worker$node):2376 $(getIP manager1):2376
  done
}

# Display status
function status {
  echo "-> list swarm nodes"
  docker-machine ssh manager1 docker node ls
  echo
  echo "-> list machines"
  docker-machine ls
}

function main () {
  createManagerNode
  createWorkerNode
  initSwarmManager
  join_node_swarm
  status
}

main