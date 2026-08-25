#!/usr/bin/env bash
set -euo pipefail

# expose.sh — expose the app publicly using ngrok (preferred) or localtunnel (fallback)
# Usage: ./expose.sh [port]
# Example: ./expose.sh 3000

PORT=${1:-3000}
SERVER_CMD="node server.js"
NGROK_BIN="ngrok"
LT_CMD="npx localtunnel"

# PIDs for cleanup
SERVER_PID=""
TUNNEL_PID=""

function cleanup() {
  echo "\nStopping tunnel and server..."
  if [ -n "$TUNNEL_PID" ]; then
    kill "$TUNNEL_PID" 2>/dev/null || true
  fi
  if [ -n "$SERVER_PID" ]; then
    kill "$SERVER_PID" 2>/dev/null || true
  fi
  exit 0
}
trap cleanup INT TERM EXIT

# Start the server (if not already running on the port)
if lsof -iTCP -sTCP:LISTEN -Pn | grep -q ":${PORT} \|:${PORT}\b"; then
  echo "Port ${PORT} already in use. Skipping starting node server."
else
  echo "Starting server: ${SERVER_CMD} (PORT=${PORT})"
  PORT=${PORT} ${SERVER_CMD} &
  SERVER_PID=$!
  echo "Server PID: ${SERVER_PID}"
  # give server a moment to bind
  sleep 0.8
fi

# Try ngrok first
if command -v ${NGROK_BIN} >/dev/null 2>&1; then
  echo "ngrok found. Starting ngrok tunnel..."
  # start ngrok in background; it exposes API at http://127.0.0.1:4040
  ${NGROK_BIN} http ${PORT} --log=stdout >/dev/null &
  TUNNEL_PID=$!
  echo "ngrok PID: ${TUNNEL_PID}"

  # Wait for ngrok API to become ready and fetch public URL
  echo -n "Waiting for ngrok to report public URL"
  for i in {1..20}; do
    sleep 0.5
    echo -n "."
    if curl -sS http://127.0.0.1:4040/api/tunnels >/dev/null 2>&1; then
      break
    fi
  done
  echo

  # Get the public URL
  TUNNELS_JSON=$(curl -sS http://127.0.0.1:4040/api/tunnels || true)
  PUBLIC_URL=$(echo "$TUNNELS_JSON" | grep -o '"public_url":"https:[^\"]*' | sed 's/"public_url":"//') || true
  if [ -n "$PUBLIC_URL" ]; then
    echo "Public URL: $PUBLIC_URL"
    echo "Open the URL on your phone or share it. (ngrok tunnel)"
    # Keep the script running to keep ngrok and server alive
    wait
  else
    echo "Failed to get ngrok public URL from API. Dumping API response:" >&2
    echo "$TUNNELS_JSON"
    cleanup
  fi

else
  echo "ngrok not found. Trying localtunnel via npx..."
  if command -v npx >/dev/null 2>&1; then
    # Use npx localtunnel; it will print the URL to stdout
    echo "Starting localtunnel (npx localtunnel --port ${PORT})"
    # Run npx localtunnel and parse its output for the URL
    # We launch it in a subshell and capture the printed URL
    LT_OUTPUT_FILE=$(mktemp)
    ( npx localtunnel --port ${PORT} >"${LT_OUTPUT_FILE}" 2>&1 ) &
    TUNNEL_PID=$!
    echo "localtunnel PID: ${TUNNEL_PID}"

    # Wait for output
    echo -n "Waiting for localtunnel to report public URL"
    for i in {1..30}; do
      sleep 0.5
      echo -n "."
      if grep -q -E "https?://[a-z0-9.-]+" "${LT_OUTPUT_FILE}" >/dev/null 2>&1; then
        break
      fi
    done
    echo

    PUB=$(grep -Eo "https?://[a-z0-9.-]+" "${LT_OUTPUT_FILE}" | head -n 1 || true)
    if [ -n "$PUB" ]; then
      echo "Public URL: $PUB"
      echo "Open the URL on your phone or share it. (localtunnel)"
      wait
    else
      echo "Failed to start localtunnel or parse its URL. Output:" >&2
      sed -n '1,200p' "${LT_OUTPUT_FILE}"
      cleanup
    fi
  else
    echo "Neither ngrok nor npx are available on this machine."
    echo "Install ngrok (https://ngrok.com/) or ensure npm/npx is available to use localtunnel:
  npm install -g localtunnel
Then re-run this script."
    cleanup
  fi
fi

# cleanup will be called on exit due to trap
