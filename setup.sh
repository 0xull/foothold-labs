#!/bin/bash

if [[ $(id -u) != "0" ]]; then
    LOG_FATAL "Please run the script as root (or use 'sudo')"
    exit 1
fi

cd "$(dirname "$0")" || exit 1
mkdir -p workspace

RED='\033[0;31m'
NC='\033[0m'

DEFAULT_IMAGE_NAME="foothold-lab"
DEFAULT_TAG='latest'
FOOTHOLD_LAB_WORKSPACE="/workspace"
FTHLD_LABS_VOLUME="FOOTHOLD_LAB_VOLUME"

LOG_INFO() {
    echo -e "[$(date +%FT%T)] [INFO] $1"
}

LOG_FATAL() {
    echo -e "[$(date +%FT%T)] [${RED}FATAL${NC}] $1" && exit 1
}

print_help() {
    echo "Usage:"
    echo "sudo ./setup.sh docker interactive [OPTIONS]"
    echo ""
    echo "Description:"
    echo "    Launches an interactive Docker container for VM in docker environment"
    echo ""
    echo "Options:"
    echo "    --privileged - Run a privileged container. This is required for nested"
    echo "                    virtualization (i.e running KVM/QEMU inside Docker)"
    echo ""
    echo "    --allow-gui   - Enables GUI application support by forwarding the host's"
    echo "                    X11 display to the container."
    echo ""
}

docker_interactive() {
    local full_image_name="${DEFAULT_IMAGE_NAME}:${DEFAULT_TAG}"
    local privileged=""
    local allow_gui=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
        --privileged)
            privileged="--privileged"
            ;;
        --allow-gui)
            allow_gui=true
            ;;
        *)
            print_help
            exit 1
        esac
        shift
    done
    
    LOG_INFO "Checking if ${FTHLD_LABS_VOLUME} volume exists..."
    if ! docker volume inspect $FTHLD_LABS_VOLUME >/dev/null 2>&1; then
        LOG_INFO "Volume not found. Creating it volume..."
        docker volume create $FTHLD_LABS_VOLUME || exit 1
        
        local vol_mount=$(docker inspect $FTHLD_LABS_VOLUME | grep -i mountpoint | cut -d : -f2 | cut -d, -f1)
        chmod 777 -R $vol_mount
    else 
        LOG_INFO "Volume found."
    fi
    
    LOG_INFO "The /linux directory is made persistent inside the volume, ${FTHLD_LABS_VOLUME}"
    docker inspect $FTHLD_LABS_VOLUME
    
    if $allow_gui; then
        LOG_INFO "Launching container with GUI support..."
        
        local xauth_var=$(echo $(xauth info | grep Auth | cut -d: -f2))
        
        docker run --privileged -it --rm \
            --net=host --env="DISPLAY" --volume="${xauth_var}:/root/.Xauthority:rw" \
            --volume $FTHLD_LABS_VOLUME:/workspace \
            --workdir "$FOOTHOLD_LAB_WORKSPACE"\
            "$full_image_name"
    else
        LOG_INFO "Launching container in standard CLI mode..."
        docker run $privileged -it --rm \
            --device /dev/net/tun:/dev/net/tun \
            --cap-add=NET_ADMIN \
            --volume $FTHLD_LABS_VOLUME:/workspace \
            --workdir "$FOOTHOLD_LAB_WORKSPACE"\
            "$full_image_name"
    fi
}


docker_main() {
    if [[ "$1" = "interactive" ]]; then
        shift
        docker_interactive "$@"
    else
        print_help
    fi
}

if [[ "$1" = "docker" ]]; then
    shift
    docker_main "$@"
elif [[ "$1" = "-h" || "$1" == "--help" ]]; then
   print_help
else
    print_help
fi