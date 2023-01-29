ARG PHP_VERSION=8.2
ARG PYTHON_VERSION=3.11
ARG RUST_VERSION=1.65.0
ARG ZIG_VERSION=0.10.0

FROM debian:unstable

# Install foundations-which-rarely-change up-front so we can cache them,
# and then install language-specific things on top
USER root
RUN apt update && apt install -y \
    build-essential linux-perf valgrind vim git libsdl2-dev wget

# Configure developer environment
ARG USER_ID
ARG GROUP_ID
RUN addgroup --gid $GROUP_ID dev || true
RUN adduser --disabled-password --gecos '' --uid $USER_ID --gid $GROUP_ID dev

# Install C++ tools
USER root
RUN apt update && apt install -y cmake clang-format-14

# Install Go tools
USER root
RUN apt update && apt install -y golang

# Install Nim tools
USER root
RUN apt update && apt install -y nim
USER dev
RUN nimble refresh

# Install PHP tools
ARG PHP_VERSION
USER root
RUN apt update && apt install -y php${PHP_VERSION}-cli php${PHP_VERSION}-dev
USER dev
RUN git clone https://github.com/Ponup/php-sdl ~/php-sdl && \
    cd ~/php-sdl && phpize && ./configure && make

# Install Python tools
ARG PYTHON_VERSION
USER root
RUN apt update && apt install -y python${PYTHON_VERSION} python${PYTHON_VERSION}-venv python${PYTHON_VERSION}-dev black
RUN mkdir -p /home/dev/.local/bin && ln -s /usr/bin/python${PYTHON_VERSION} /home/dev/.local/bin/python3
ENV PATH="/home/dev/.local/bin:$PATH"

# Install Rust tools
ARG RUST_VERSION
USER dev
RUN wget -qO - https://sh.rustup.rs | sh -s -- --default-toolchain ${RUST_VERSION} -y
ENV PATH="/home/dev/.cargo/bin:$PATH"
RUN cargo search foo

# Install Zig tools
ARG ZIG_VERSION
USER dev
RUN wget https://ziglang.org/download/${ZIG_VERSION}/zig-linux-$(uname -m)-${ZIG_VERSION}.tar.xz -O /tmp/zig.tar.xz && \
    mkdir ~/.zig && tar --strip-components=1 -C ~/.zig -xf /tmp/zig.tar.xz && rm -f /tmp/zig.tar.gz
ENV PATH="/home/dev/.zig:$PATH"

# Get ready to go
USER dev
WORKDIR /home/dev/rosettaboy
CMD /bin/bash
