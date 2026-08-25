#!/usr/bin/env bash
set -euo pipefail

# run.sh — convenience script to run the admin-system app locally
# Usage:
#   ./run.sh node        # run with `node server.js` (dev, no docker)
#   ./run.sh docker      # build docker image and run container
#   ./run.sh compose     # docker compose up --build -d
#   ./run.sh stop        # stop and remove docker container
#   ./run.sh help        # show help

REPO_NAME="admin-system"
IMAGE_NAME="admin-system:latest"
CONTAINER_NAME="admin-system"
PORT=${PORT:-3000}

function help() {
  cat <<'EOF'
run.sh — convenient helpers to run the admin-system demo

Usage:
  ./run.sh node        # run with `node server.js` (dev, no docker)
  ./run.sh docker      # build docker image and run container
  ./run.sh compose     # docker compose up --build -d
  ./run.sh stop        # stop and remove docker container
  ./run.sh logs        # follow container logs
  ./run.sh help        # show this help

Notes:
 - server.js listens on 0.0.0.0:3000 by default. To change port, set PORT env var, e.g.
     PORT=8080 ./run.sh docker
 - For mobile access from another device, make sure the machine running this script is reachable on the network
   and any firewall allows the chosen port.
 - This repository ships a demo front-end password (admin123). Do NOT use in production.
EOF
}

if [ $# -lt 1 ]; then
  help
  exit 0
fi

CMD="$1"

case "$CMD" in
  help)
    help
    ;;

  node)
    if ! command -v node >/dev/null 2>&1; then
      echo "Error: node is not installed or not in PATH" >&2
      exit 1
    fi
    echo "Starting server with node server.js (PORT=${PORT})..."
    node server.js
    ;;

  docker)
    if ! command -v docker >/dev/null 2>&1; then
      echo "Error: docker is not installed or not in PATH" >&2
      exit 1
    fi

    echo "Building Docker image: ${IMAGE_NAME}"
    docker build -t ${IMAGE_NAME} .

    # If a container with the same name exists, stop and remove it
    if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
      echo "Removing existing container: ${CONTAINER_NAME}"
      docker rm -f ${CONTAINER_NAME} >/dev/null 2>&1 || true
    fi

    echo "Running container ${CONTAINER_NAME} -> host port ${PORT}"
    docker run -d --name ${CONTAINER_NAME} -p ${PORT}:3000 -e PORT=3000 ${IMAGE_NAME}
    echo "Container started. Run './run.sh logs' to follow logs or open http://<host-ip>:${PORT}"
    ;;

  compose)
    if ! command -v docker >/dev/null 2>&1; then
      echo "Error: docker is not installed or not in PATH" >&2
      exit 1
    fi
    if ! docker compose version >/dev/null 2>&1; then
      echo "Warning: 'docker compose' not available. Trying 'docker-compose'..."
      if ! command -v docker-compose >/dev/null 2>&1; then
        echo "Error: neither 'docker compose' nor 'docker-compose' found" >&2
        exit 1
      else
        echo "Using docker-compose"
        docker-compose up --build -d
        exit 0
      fi
    fi

    echo "Bringing up with docker compose (build + detached)"
    docker compose up --build -d
    ;;

  stop)
    echo "Stopping and removing container ${CONTAINER_NAME} (if exists)"
    if command -v docker >/dev/null 2>&1; then
      docker rm -f ${CONTAINER_NAME} >/dev/null 2>&1 || true
    fi
    ;;

  logs)
    if ! command -v docker >/dev/null 2>&1; then
      echo "Error: docker is not installed or not in PATH" >&2
      exit 1
    fi
    docker logs -f ${CONTAINER_NAME}
    ;;

  *)
    echo "Unknown command: $CMD" >&2
    help
    exit 2
    ;;

esac
