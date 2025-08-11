FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    sudo \
    software-properties-common \
    qemu-system-x86 \
    qemu-kvm \
    cpu-checker \
    openssh-server \
    git \
    vim \
    wget \
    && rm -rf /var/lib/apt/lists/*
    
RUN useradd -m -s /bin/bash dev && groupadd kvm && adduser dev sudo && adduser dev kvm
RUN echo 'dev ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

RUN echo 'dev:dev' | chpasswd
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/ssh_config
RUN mkdir /var/run/sshd

EXPOSE 22

USER dev
WORKDIR /home/dev

CMD [ "/bin/bash", "-c", "sudo /usr/sbin/sshd && /bin/bash" ]