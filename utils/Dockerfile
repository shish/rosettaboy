FROM debian:unstable AS final
USER root
RUN apt update && apt install -y \
    build-essential linux-perf valgrind vim git mercurial libsdl2-dev wget curl sudo

# Configure developer environment
ARG USER_ID=1000
ARG GROUP_ID=$USER_ID
RUN addgroup devgrp --gid $GROUP_ID \
    && adduser --disabled-password --gecos '' --uid $USER_ID --gid $GROUP_ID dev \
    && echo dev ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/dev \
    && chmod 0440 /etc/sudoers.d/dev

# If debian unstable has recent-enough versions, use them
USER root
RUN apt update && apt install -y \
    cmake clang clang-format-14 libfmt-dev \
    golang golang-1.24 \
    php8.4-cli \
    python3.13 python3.13-venv python3.13-dev \
    pypy3 pypy3-venv \
    cargo

# For places where debian unstable is lacking, use DIY devkits
ENV DEVKITS_BASE=https://github.com/shish/rosettaboy-devkits/releases/download/nightly
ENV PATH="/opt/nim/bin:$PATH"
RUN wget -q ${DEVKITS_BASE}/rosettaboy-zig-dev_0.14.1_$(dpkg-architecture -q DEB_BUILD_ARCH).deb
RUN wget -q ${DEVKITS_BASE}/rosettaboy-nim-dev_2.2.4_$(dpkg-architecture -q DEB_BUILD_ARCH).deb
RUN apt install -y ./*.deb

# Get ready to go
USER dev
WORKDIR /home/dev/rosettaboy
CMD ["/bin/bash"]
