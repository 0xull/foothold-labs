#!/bin/bash

cd "$(dirname "$0")" || exit 1
mkdir -p workspace

RED='\033[0;31m'
NC='\033[0m'

DEFAULT_IMAGE_NAME="foothold-lab"
DEFAULT_TAG='latest'

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
    
    
    if $allow_gui; then
        LOG_INFO "Launching container with GUI support..."
        docker run "$privileged" -it --rm \
            --device /dev/kvm \
            -v "/tmp/.X11-unix:/tmp/.X11-unix:rw" \
            -e DISPLAY=$DISPLAY \
            --volume "${PWD}/workspace:/home/dev/workspace" \
            "$full_image_name"
    else
        LOG_INFO "Launching container in standard CLI mode..."
        docker run "$privileged" -it --rm \
            --device /dev/net/tun:/dev/net/tun \
            --cap-add=NET_ADMIN \
            --volume "${PWD}/workspace:/home/dev/workspace" \
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