FROM debian:unstable
RUN apt update
RUN apt install -y \
    build-essential linux-perf valgrind vim git libsdl2-dev \
    cmake clang-format-14 \
    golang \
    python3 python3-venv black \
    php-cli \
    rust-all \
    nim
RUN apt install -y wget
RUN wget https://ziglang.org/download/0.10.0/zig-linux-$(uname -m)-0.10.0.tar.xz -O /tmp/zig.tar.xz && \
    tar -C /tmp -xf /tmp/zig.tar.xz && \
    ln -s /tmp/zig*/zig /usr/local/bin/zig

ARG USER_ID
ARG GROUP_ID
RUN addgroup --gid $GROUP_ID user || true
RUN adduser --disabled-password --gecos '' --uid $USER_ID --gid $GROUP_ID user
USER user

WORKDIR /home/dev
CMD /bin/bash
