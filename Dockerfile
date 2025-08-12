FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    # Core build tools
    build-essential \
    gcc-multilib \
    make \
    pkg-config \
    bison \
    flex \
    ninja-build \
    # Kernel-specific build tools
    libncurses5-dev \
    libssl-dev \
    bc \
    lzop \
    # Virtualization/Emulation
    qemu-system-x86 \
    qemu-system-arm \
    # Development & debugging
    git \
    gdb \
    python3 \
    vim \
    # System & networking utilities
    software-properties-common \
    minicom \
    curl \
    wget \
    sudo \
    iproute2 \
    netcat-openbsd \
    dnsmasq \
    iputils-ping \
    samba \
    openssh-server \
    # Miscellaneous
    asciinema \
    bash-completion \
    # Glib and pixman for qemu
    libglib2.0-dev \
    libpixman-1-dev \
&& apt-get clean && rm -rf /var/lib/apt/lists/*

ARG ARG_UID=1000
ARG ARG_GID=1000

RUN groupadd --gid $ARG_GID dev && \
    useradd --uid $ARG_UID --gid $ARG_GID -ms /bin/bash dev && \
    adduser dev sudo && \
    groupadd kvm && \
    adduser dev kvm

RUN echo -n 'dev:dev' | chpasswd

RUN echo 'dev ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/dev-nopasswd

RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/ssh_config
RUN mkdir /var/run/sshd

EXPOSE 22

USER dev
WORKDIR /home/dev

RUN echo "add-auto-load-safe-path /" > ~/.gdbinit

CMD [ "/bin/bash", "-c", "sudo /usr/sbin/sshd && /bin/bash" ]