#!/usr/bin/env bash
set -euo pipefail

#/ Usage: $(basename "$0") -v <forge_version> [-s yes|no] [-w <working_directory>]
#/ Options:
#/   -v, --forge-version     Forge version (including build number), e.g. "1.20.1-41.2.0"
#/   -s, --startup           Install a systemd service? "yes" or "no" (default: no)
#/   -w, --working-directory Directory to install server into (default: current directory)
#/   -h, --help              Show this help message

FORGE_VERSION=""
ADD_TO_STARTUP="no"
WORKING_DIRECTORY="$(pwd)"
SYSTEMD_USER="$(whoami)"

usage() {
  grep '^#/' "$0" | sed 's/^#\///'
  exit 2
}

# Parse CLI args
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)           usage ;;
    -v|--forge-version)  FORGE_VERSION="$2"; shift 2 ;;
    -s|--startup)        ADD_TO_STARTUP="$2"; shift 2 ;;
    -w|--working-directory)
                         WORKING_DIRECTORY="$2"; shift 2 ;;
    *)
      echo "Error: Unrecognized argument: $1" >&2
      usage
      ;;
  esac
done

# Validate required options
if [[ -z "$FORGE_VERSION" ]]; then
  echo "Error: --forge-version is required." >&2
  usage
fi

if [[ ! "$ADD_TO_STARTUP" =~ ^(yes|no)$ ]]; then
  echo "Error: --startup must be 'yes' or 'no'; got '$ADD_TO_STARTUP'." >&2
  usage
fi

# Ensure working dir exists, then switch into it
if [[ ! -d "$WORKING_DIRECTORY" ]]; then
  echo "Error: Directory '$WORKING_DIRECTORY' does not exist." >&2
  exit 1
fi
cd "$WORKING_DIRECTORY"

# Functions with safe names and quotes!

download_forge_installer() {
  echo "[1/6] Downloading Forge $FORGE_VERSION…"
  curl -L --fail -o forge-installer.jar \
    "https://maven.minecraftforge.net/net/minecraftforge/forge/$FORGE_VERSION/forge-$FORGE_VERSION-installer.jar"
}

run_forge_installer() {
  echo "[2/6] Running Forge installer…"
  command -v java >/dev/null 2>&1 || { echo "Error: Java not found." >&2; exit 1; }
  java -jar forge-installer.jar --installServer
}

add_eula() {
  echo "[3/6] Agreeing to EULA…"
  echo "eula=true" > eula.txt
}

configure_headless_start() {
  echo "[4/6] Patching run.sh for headless mode…"
  if [[ -f run.sh ]]; then
    sed -E -i.bak \
      's#(java .*unix_args.txt)(.*)#\1 -nogui\2#' run.sh
  else
    echo "Warning: run.sh not found; skipping headless patch." >&2
  fi
}

download_server_properties() {
  echo "[5/6] Downloading default server.properties…"
  curl -L --fail -o server.properties \
    "https://raw.githubusercontent.com/vxgxp/forge-minecraft-linux-installer/main/server.properties"
}

add_systemd_service() {
  if [[ "$ADD_TO_STARTUP" == "yes" ]]; then
    echo "[6/6] Installing systemd service…"
    sudo tee /etc/systemd/system/forge-server.service >/dev/null <<EOF
[Unit]
Description=Forge Minecraft Server
After=network.target

[Service]
WorkingDirectory=$WORKING_DIRECTORY
ExecStart=$WORKING_DIRECTORY/run.sh
User=$SYSTEMD_USER
Restart=always
Environment=PATH=/usr/bin:/usr/local/bin

[Install]
WantedBy=multi-user.target
EOF
    sudo systemctl daemon-reload
    sudo systemctl enable forge-server.service
  else
    echo "[6/6] Skipping systemd service installation."
  fi
}

# Launch the func
download_forge_installer
run_forge_installer
add_eula
configure_headless_start
download_server_properties
add_systemd_service

echo "All done! Your Forge server is ready to go!" 
