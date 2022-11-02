FROM debian:unstable
# Install foundations-which-rarely-change up-front so we can cache them,
# and then install language-specific things on top
RUN apt update && apt install -y \
    build-essential linux-perf valgrind vim git libsdl2-dev wget
RUN apt update && apt install -y \
    cmake clang-format-14 \
    golang \
    python3.11 python3.11-venv black \
    php-cli php-dev \
    rust-all \
    nim
RUN wget https://ziglang.org/download/0.10.0/zig-linux-$(uname -m)-0.10.0.tar.xz -O /tmp/zig.tar.xz && \
    tar -C /tmp -xf /tmp/zig.tar.xz && \
    ln -s /tmp/zig*/zig /usr/local/bin/zig
RUN git clone https://github.com/shish/php-sdl /tmp/php-sdl && \
    cd /tmp/php-sdl && phpize && ./configure && make && make install

ARG USER_ID
ARG GROUP_ID
RUN addgroup --gid $GROUP_ID user || true
RUN adduser --disabled-password --gecos '' --uid $USER_ID --gid $GROUP_ID user
USER user

WORKDIR /home/dev
CMD /bin/bash
