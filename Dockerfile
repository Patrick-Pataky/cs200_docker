# Base image
FROM ubuntu:latest

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV USERNAME=cs200
ENV PASSWORD=epfl

# Must be x86_64, macOS, or arm64
ENV ARCH=x86_64
ENV NB_THREADS=32

# Install required packages
RUN apt-get update && apt-get install -y software-properties-common \
    && add-apt-repository ppa:ubuntu-toolchain-r/test

RUN apt-get update && apt-get install -y sudo autoconf automake rsync software-properties-common \
    autotools-dev curl python3 python3-pip libmpc-dev libmpfr-dev libgmp-dev \
    gawk build-essential bison flex texinfo gperf libtool patchutils bc \
    zlib1g-dev libexpat-dev ninja-build git cmake make libglib2.0-dev libslirp-dev \
    openssh-server gtkwave jq iverilog g++-13 gcc-13 libdw-dev libelf-dev help2man perl ccache \
    libgoogle-perftools-dev numactl perl-doc libfl2 libfl-dev zlib1g \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-13 100 \
    && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-13 100

# Set up user
RUN useradd -m -d /home/$USERNAME -s /bin/bash -G sudo $USERNAME \
    && echo "$USERNAME:$PASSWORD" | chpasswd \
    && echo "root:$PASSWORD" | chpasswd

# Install RISC-V GNU toolchain
RUN git clone https://github.com/riscv/riscv-gnu-toolchain /tmp/riscv-gnu-toolchain
RUN cd /tmp/riscv-gnu-toolchain \
    && ./configure --prefix=/opt/riscv \
    && make linux -j "$NB_THREADS" \
    && rm -rf /tmp/riscv-gnu-toolchain

# Install verible
RUN mkdir /opt/verible \
    && curl -s https://api.github.com/repos/chipsalliance/verible/releases/latest | \
       jq -r ".assets[] | select(.name | test(\"${ARCH}\")) | .browser_download_url" | \
       xargs curl -L -o /tmp/verible.tar.gz \
    && tar xf /tmp/verible.tar.gz -C /opt/verible \
    && rm /tmp/verible.tar.gz \
    && echo "export PATH=\$PATH:/opt/verible/bin" >> /home/$USERNAME/.bashrc

# Install cppdap
RUN git clone https://github.com/google/cppdap.git /tmp/cppdap \
    && cd /tmp/cppdap \
    && git submodule update --init \
    && mkdir build \
    && cd build \
    && cmake .. \
    && make install -j "$NB_THREADS" \
    && rm -rf /tmp/cppdap

# Install Verilator
RUN git clone https://github.com/verilator/verilator /tmp/verilator \
    && cd /tmp/verilator \
    && unset VERILATOR_ROOT \
    && git checkout stable \
    && autoconf \
    && ./configure \
    && make -j "$NB_THREADS" \
    && make install \
    && rm -rf /tmp/verilator

# Compile Vtb (RISC-V debugger)
RUN git clone https://github.com/BugraEryilmaz/Vtb_src.git /tmp/vtb \
    && cd /tmp/vtb \
    && make -f Vtb.mk -j "$NB_THREADS" \
    && chmod +x Vtb \
    && cp Vtb /usr/bin \
    && rm -rf /tmp/vtb

# Set up X11 Forwarding
RUN echo "X11Forwarding yes" >> /etc/ssh/sshd_config

# Set up configuration for SSH
RUN mkdir /var/run/sshd \
    && sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd \
    && echo "export VISIBLE=now" >> /etc/profile

USER $USERNAME
RUN ssh-keygen -A

USER root

# Set up CS200 environment
ENV SRC=/tmp/$USERNAME/src
RUN bash -c 'mkdir -p $SRC/lab{1..3}'

COPY project.tar.xz $SRC/lab1/
COPY gol-template.s $SRC/lab1/gol.s

RUN tar xf $SRC/lab1/project.tar.xz -C $SRC/lab1/ \
    && cp /usr/bin/Vtb $SRC/lab1/

RUN chown -R $USERNAME:$USERNAME $SRC

# Expose SSH port
EXPOSE 22

# Start SSH service
CMD ["/usr/sbin/sshd", "-D"]
