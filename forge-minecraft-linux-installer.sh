#!/bin/bash

set -e

# Default options
FORGE_VERSION=""
ADD_TO_STARTUP="no"
WORKING_DIRECTORY=$(pwd)
SYSTEMD_USER=$(whoami)

usage() {
    grep '^#/' < "$0" | cut -c 4-
    exit 2
}

while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)
            usage
            ;;
        -v|--forge-version)
            FORGE_VERSION=$2
            shift 2
            ;;
        -s|--startup|-startup)
            ADD_TO_STARTUP=$2
            shift 2
            ;;
        -w|--working-directory)
            WORKING_DIRECTORY=$2
            shift 2
            ;;
        *)
            echo "Unrecognized argument: $1" >&2
            usage
            ;;
    esac
done

if [[ -z $FORGE_VERSION ]]; then
    echo "The FORGE_VERSION value is empty and needs to be set with -v or --forge-version"
    usage
    exit 1
fi

if [[ -z $ADD_TO_STARTUP ]]; then
    echo "The ADD_TO_STARTUP value is empty and needs to be set with --option-2"
    usage
    exit 1
fi

download-forge-installer() {
    
    echo "Downloading Forge version $FORGE_VERSION"
    
    curl -o forge-installer.jar https://maven.minecraftforge.net/net/minecraftforge/forge/$FORGE_VERSION/forge-$FORGE_VERSION-installer.jar
    
    if [ $? -ne 0 ]; then
        echo "Error: The download of Forge version $FORGE_VERSION failed. Please check the version to ensure you've included the full build number and try again"
        exit 1
    fi
}

run-forge-installer() {

    echo "Checking for Java and running the Official Forge installer"

    if ! command -v java >/dev/null 2>&1; then
        echo "Error: Java is either not properly installed or within your HOME path. Please install Java and try again."
        exit 1
    fi

    java -jar forge-installer.jar --installServer

}

add-eula-agreement() {
            
    echo "Adding EULA agreement to eula.txt"
    
    echo "eula=true" > eula.txt
    
}

configure-headless-start() {

    echo "Configuring headless start of the Forge server by adding -nogui to the run.sh file"

    sed -i 's#java @user_jvm_args.txt @libraries/net/minecraftforge/forge/[^/]*/unix_args.txt "$@"#java @user_jvm_args.txt @libraries/net/minecraftforge/forge/[^/]*/unix_args.txt -nogui "$@"#' run.sh
}

download-server-properties() {

    echo "Downloading a default server.properties file"

    curl -o server.properties https://raw.githubusercontent.com/itzg/docker-minecraft-server/master/server.properties
}

add-run-script-to-systemd() {

    ### Only run if ADD_TO_STARTUP is set to yes

    if [[ $ADD_TO_STARTUP == "no" ]]; then
        echo "Skipping adding the Minecraft server to startup"
        
    fi

        if [[ $ADD_TO_STARTUP == "yes" ]]; then

        echo "Adding a systemd service to start the Minecraft server on boot"
        echo "You will be prompted for your sudo password to add the systemd service"

        sudo tee /etc/systemd/system/forge-server.service >/dev/null <<-EOF

[Unit]
Description=Forge Minecraft Server

[Service]
ExecStart=$WORKING_DIRECTORY/run.sh
Restart=always
User=$SYSTEMD_USER
Group=$SYSTEMD_USER
Environment=PATH=/usr/bin:/usr/local/bin
WorkingDirectory=$WORKING_DIRECTORY

[Install]
WantedBy=multi-user.target

EOF

        sudo systemctl daemon-reload
        sudo systemctl enable forge-server.service
        fi
}
    
download-forge-installer;
run-forge-installer;
add-eula-agreement;
configure-headless-start;
download-server-properties;
add-run-script-to-systemd;
