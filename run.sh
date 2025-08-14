LOG_FATAL() {
    echo -e "[$(date +%FT%T)] [FATAL] $1"
}

LOG_INFO() {
    echo -e "[$(date +%FT%T)] [INFO] $1" && exit 1
}

FTHLD_LABS_LV="foothold-labs.qcow2"
FTHLD_LABS_LV_SIZE="20G"
ISO_FILE="debian-13.0.0-amd64-netinst.iso"

LOG_INFO "Checking for ISO file: ${ISO_FILE}"
if ! file $ISO_FILE >/dev/null 2>&1; then
    LOG_INFO "ISO file not found. If you've got one, then update the <ISO_FILE=""> variable to point to it"
    LOG_INFO "Or download from https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-13.0.0-amd64-netinst.iso"
else
    LOG_INFO "ISO file found"
fi

print_help() {
    echo "Usage:"
    echo "./run.sh [command] [OPTIONS]"
    echo ""
    echo "Comands:"
    echo "  create-vm -- Setups a headless VM with the installer ISO attached and redirect its console to our terminal."
    echo "               As soon as the VM starts, you will see some text. Quickly press the ESC key to interrupt"
    echo "               the automatic boot process."
    echo "               You will get a boot: prompt."
    echo "               At this prompt, type install console=ttyS0 and press Enter. Make sure to select and"
    echo "               install the "SSH server" option during the task selection step"
    echo ""
    echo ""
    echo "  start-vm  -- Running your new headless VM. This sets up user-mode networking and, most importantly, forwards"
    echo "               port 2222 on your host machine to port 22 (the SSH port) inside the VM."
    echo ""
    echo "Options:"
    echo "The following options are supported:"
    echo "  create-vm [-mem] -- Allocate RAM size to the VM. Example: 4G"
    echo "  create-vm [-hda] -- Creates virtual hard disk with size that will be attached to the VM. Example: 20G"
    echo ""
}

create_vm() {
    local memory_sise=""
    local hda_size=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -mem)
                if [[ -z "$2" ]]; then
                    echo "Error: no value found for mem" >&2
                    print_help
                    exit 1
                fi
                memory_sise=$2
                shift
                shift
                ;;
            -hda)
                if [[ -z "$2" ]]; then
                    echo "Error: no value for hda" >&2
                    print_help
                    exit 1
                hda_size=$2
                shift
                shift
                ;;
            *)
                print_help
                exit 1
        esac
    done
    
    LOG_INFO "Checking for a logical volume: ${FTHLD_LABS_LV}"
    if ! file $FTHLD_LABS_LV >/dev/null 2>&1; then
        LOG_INFO "LV not found. Creating a QEMU copy-on-write version 2 format: ${FTHLD_LABS_LV} with ${hda_size}"
        qemu-img create -f qcow2 $FTHLD_LABS_LV $hda_size
    
        LOG_INFO "LV Created:"
    else
        LOG_INFO "LV found:"
    fi
    
    file $FTHLD_LABS_LV
    
    LOG_INFO "Creating a VM..."
    qemu-system-x86_64 \
        -machine accel=kvm \
        -m $memory_sise \
        -nographic \
        -hda $FTHLD_LABS_LV \
        -cdrom $ISO_FILE \
        -boot d
}

start_vm() {
    if [[ -z "$1" ]]; then
        print_help
        exit 1
    fi
    
    if ! file $FTHLD_LABS_LV >/dev/null 2>&1; then
        LOG_FATAL "Logical volume not found."
        LOG_INFO "Run qemu-img create -f qcow2 [name] [size] to create LV." 
        LOG_INFO "Or run create-vm to create both LV and VM."
        exit 1
    fi
    
    LOG_INFO "Spinning up..."
    qemu-system-x86_64 \
        -machine accel=kvm \
        -m $1 \
        -nographic \
        -hda $FTHLD_LABS_LV \
        -netdev user,id=net0,hostfwd=tcp::2222-:22 \
        -device e1000,netdev=net0
}

if [[ "$1" == "create-vm" ]]; then
    shift
    LOG_INFO "Creating VM..."
    create_vm "$@"
elif [[ "$1" == "start-vm" ]]; then
    shift
    LOG_INFO "Starting VM..."
    start_vm "$@"
else
    print_help
fi
