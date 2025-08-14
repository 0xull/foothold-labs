ISO_URL="https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-13.0.0-amd64-netinst.iso"
VM_DISK_SIZE="20G"
VM_MEM_SIZE="4G"
ISO_FILE="debian-13.0.0-amd64-netinst.iso"
VM_DISK_FILE="foothold-labs.qcow2"

RED='\033[0;31m'
NC='\033[0m'

LOG_FATAL() {
    echo -e "[$(date +%FT%T)] [${RED}FATAL${NC}] $1"
    exit 1
}

LOG_INFO() {
    echo -e "[$(date +%FT%T)] [INFO] $1"
}

check_deps() {
    LOG_INFO "Checking for required dependencies..."
    for cmd in qemu-system-x86_64 qemu-img wget; do
        if ! command -v "$cmd" &>/dev/null; then
            LOG_FATAL "Required command '$cmd' not found. Please install it."
        fi
    done
    LOG_INFO "All required dependencies found."
}

print_help() {
    echo "Usage: $0 [command]"
    echo ""
    echo "A tool to manage a headless QEMU/KVM virtual machine."
    echo ""
    echo "Comands:"
    echo "  create-vm [-mem_size SIZE] [-hda_size SIZE]"
    echo "     Creates the VM disk, and starts the OS installation."
    echo "     -mem_size: Set VM RAM (e.g, 4G). Default: ${VM_MEM_SIZE}."
    echo "     -hda_size: Set virtual disk size (e.g., 30G) Default: ${VM_DISK_SIZE}"
    echo ""
    echo "  start-vm [-mem_size]"
    echo "     Starts the existing the existing headless VM with SSH forwarding port on 2222."
    echo "     -mem_size: Set VM RAM (e.g, 4G). Default: ${VM_MEM_SIZE}."
    echo ""
    echo "  help"
    echo "     Displays this help message."
    echo ""
    echo "Installation instruction for 'create-vm':"
    echo "  1. At the boot menu, press ESC."
    echo "  2. At the 'boot:' prompt, type 'install console=ttyS0' and press Enter."
    echo "  3. During installation, ensure you select and install the 'SSH server'."
    echo ""
}

create_vm() {
    local memory_size="$VM_MEM_SIZE"
    local disk_size="$VM_DISK_SIZE"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -mem_size)
                [[ -z "$2" ]] && LOG_FATAL "'-mem_size' requires a value. (e.g., 4G)"
                memory_size="$2"
                shift 2
                ;;
            -hda_size)
                [[ -z "$2" ]] && LOG_FATAL"'-hda_size' requires a value. (e.g., 20G)"
                disk_size="$2"
                shift 2
                ;;
            *)
                LOG_FATAL "Unknown option for 'create-vm' command"
                ;;
        esac
    done
    
    LOG_INFO "Checking for disk image: ${VM_DISK_FILE}"
    if [ -f "$VM_DISK_FILE" ]; then
        LOG_INFO "Disk already exists. Skipping creation."
    else
        LOG_INFO "Creating QEMU disk image '${VM_DISK_FILE} with ${disk_size} size..."
        qemu-img create -f qcow2 "$VM_DISK_FILE" "$disk_size" || LOG_FATAL "Failed to create disk image"
        LOG_INFO "Disk image created successfully."
    fi
    
    file $VM_DISK_FILE
    
    LOG_INFO "Starting VM for installation with ${memory_size} of RAM..."
    qemu-system-x86_64 \
        -machine accel=kvm \
        -m "$memory_size" \
        -nographic \
        -hda "$VM_DISK_FILE" \
        -cdrom "$ISO_FILE" \
        -boot d
}

start_vm() {
    local memory_size="$VM_MEM_SIZE"
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -mem_size)
                [[ -z "$1" ]] && LOG_FATAL "'-mem_size' requires a value. (e.g., 4G)"
                memory_size="$2"
                shift 2
                ;;
            *)
                LOG_FATAL "Unknown option for start-vm: $1"
                ;;
        esac
    done
    
    if [ ! -f "$VM_DISK_FILE" ]; then
        LOG_FATAL "VM disk image '$VM_DISK_FILE' not found. Run 'create-vm' first"
    fi
    
    LOG_INFO "Starting headless VM with ${memory_size} RAM. SSH on localhost:2222."
    qemu-system-x86_64 \
        -machine accel=kvm \
        -m $memory_size \
        -nographic \
        -hda $VM_DISK_FILE \
        -netdev user,id=net0,hostfwd=tcp::2222-:22 \
        -device e1000,netdev=net0
}

# Check for required dependencies called in this script
check_deps

LOG_INFO "Checking for ISO file: ${ISO_FILE}"
if [ ! -f "$ISO_FILE" ]; then
    LOG_INFO "ISO file not found in directory. Attempting download..."
    wget -0 $ISO_FILE $ISO_URL || LOG_FATAL "Failed to download ISO image from ${ISO_URL}"
fi

LOG_INFO "ISO file found."

case $1 in
    create-vm)
        shift
        create_vm "$@"
        ;;
    start-vm)
        shift
        start_vm "$@"
        ;;
    help|--help|-h)
        print_help
        ;;
    *)
        if [[ -z "$1" ]]; then
            LOG_INFO "No command was specified."
        else
            LOG_INFO "Command not recognized: ${1}"
        fi
        print_help
        exit 1
        ;;
esac