ARG GO_VERSION=1.21.1
ARG NIM_VERSION=2.0.2
ARG PHP_VERSION=8.2.10
ARG PYTHON_VERSION=3.11.5
ARG RUST_VERSION=1.72.0
ARG ZIG_VERSION=0.11.0


#######################################################################
# Foundations

FROM debian:unstable AS base-builder
# Install foundations-which-rarely-change up-front so we can cache them,
# and then install language-specific things on top
USER root
RUN apt update && apt install -y \
    build-essential linux-perf valgrind vim git mercurial libsdl2-dev wget curl

# Configure developer environment
ARG USER_ID=1000
ARG GROUP_ID=$USER_ID
RUN addgroup --gid $GROUP_ID dev || true \
    && adduser --disabled-password --gecos '' --uid $USER_ID --gid $GROUP_ID dev \
    && apt-get update \
    && apt-get install -y sudo \
    && echo dev ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/dev \
    && chmod 0440 /etc/sudoers.d/dev


#######################################################################
# Go

FROM base-builder AS go-builder
ARG GO_VERSION
USER dev
RUN wget -nv https://go.dev/dl/go${GO_VERSION}.linux-$(dpkg --print-architecture).tar.gz -O - | tar -xz -C /tmp && \
    mv /tmp/go /home/dev/.go
ENV PATH="/home/dev/.go/bin:$PATH"


#######################################################################
# Nim

FROM base-builder AS nim-builder
ARG NIM_VERSION
USER dev
ENV PATH="/home/dev/.nim/bin:$PATH"
# choosenim doesn't work on arm64 D:
#ENV CHOOSENIM_CHOOSE_VERSION=${NIM_VERSION}
#RUN curl https://nim-lang.org/choosenim/init.sh -sSf | sh -s -- -y && \
#    nimble refresh
RUN wget -nv https://nim-lang.org/download/nim-${NIM_VERSION}.tar.xz -O - | tar -xJ -C /tmp && \
    cd /tmp/nim-${NIM_VERSION} && \
    ./build.sh && \
    bin/nim c koch && \
    ./koch boot -d:release && \
    ./koch tools && \
    ./install.sh /tmp/install-nim && \
    mv /tmp/install-nim/nim /home/dev/.nim && \
    cp ./bin/nimble /home/dev/.nim/bin/ && \
    nimble refresh

#######################################################################
# PHP

FROM base-builder AS php-builder
ARG PHP_VERSION
RUN apt-get install -y libxml2-dev libsqlite3-dev libssl-dev autoconf
USER dev
RUN wget -nv https://www.php.net/distributions/php-${PHP_VERSION}.tar.gz -O - | tar -xz -C /tmp && \
    cd /tmp/php-${PHP_VERSION} && ./configure --prefix=/home/dev/.php --with-openssl && make -j install
ENV PATH="/home/dev/.php/bin:$PATH"
RUN curl https://getcomposer.org/installer | php -- --quiet --install-dir=/home/dev/.php/bin/ --filename=composer
RUN git clone https://github.com/Ponup/php-sdl ~/php-sdl && \
    cd ~/php-sdl && phpize && ./configure && make -j


#######################################################################
# Python

FROM base-builder AS py-builder
ARG PYTHON_VERSION
USER root
RUN apt-get install -y --no-install-recommends \
    make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev \
    libsqlite3-dev wget curl llvm libncurses5-dev xz-utils tk-dev \
    libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev && \
    apt-get install -y mecab-ipadic-utf8
USER dev
ENV PYENV_ROOT="/home/dev/.pyenv"
ENV PATH="/home/dev/.pyenv/shims:/home/dev/.pyenv/bin:$PATH"
RUN git clone --depth=1 https://github.com/yyuu/pyenv /home/dev/.pyenv && \
    pyenv install ${PYTHON_VERSION} && \
    pyenv global ${PYTHON_VERSION} && \
    pyenv rehash


#######################################################################
# Rust

FROM base-builder AS rs-builder
ARG RUST_VERSION
USER dev
ENV PATH="/home/dev/.cargo/bin:$PATH"
RUN wget -nv -qO - https://sh.rustup.rs | sh -s -- --default-toolchain ${RUST_VERSION} -y && \
    cargo search foo
# Cranelift is only in nightly
RUN rustup toolchain install nightly \
    && rustup component add rustc-codegen-cranelift-preview --toolchain nightly


#######################################################################
# Zig

FROM base-builder AS zig-builder
ARG ZIG_VERSION
USER dev
RUN wget -nv https://ziglang.org/builds/zig-linux-$(uname -m)-${ZIG_VERSION}.tar.xz -O /tmp/zig.tar.xz && \
    mkdir ~/.zig && tar --strip-components=1 -C ~/.zig -xf /tmp/zig.tar.xz && rm -f /tmp/zig.tar.gz


#######################################################################
# Final image

FROM base-builder AS final

ARG USER_ID
ARG GROUP_ID

# Install C/C++ tools
USER root
RUN apt update && apt install -y cmake clang clang-format-14 libfmt-dev

# Install Go tools
COPY --from=go-builder --chown=${USER_ID}:${GROUP_ID} /home/dev/.go /home/dev/.go
ENV PATH="/home/dev/.go/bin:$PATH"

# Install Nim tools
COPY --from=nim-builder --chown=${USER_ID}:${GROUP_ID} /home/dev/.nim /home/dev/.nim
ENV PATH="/home/dev/.nim/bin:$PATH"

# Install PHP tools
COPY --from=php-builder --chown=${USER_ID}:${GROUP_ID} /home/dev/.php /home/dev/.php
ENV PATH="/home/dev/.php/bin:$PATH"

# Install Python tools
COPY --from=py-builder --chown=${USER_ID}:${GROUP_ID} /home/dev/.pyenv /home/dev/.pyenv
ENV PYENV_ROOT="/home/dev/.pyenv"
ENV PATH="/home/dev/.pyenv/shims:/home/dev/.pyenv/bin:$PATH"

# Install Rust tools
COPY --from=rs-builder --chown=${USER_ID}:${GROUP_ID} /home/dev/.rustup /home/dev/.rustup
COPY --from=rs-builder --chown=${USER_ID}:${GROUP_ID} /home/dev/.cargo /home/dev/.cargo
ENV PATH="/home/dev/.cargo/bin:$PATH"

# Install Zig tools
COPY --from=zig-builder --chown=${USER_ID}:${GROUP_ID} /home/dev/.zig /home/dev/.zig
ENV PATH="/home/dev/.zig:$PATH"

# Get ready to go
USER dev
WORKDIR /home/dev/rosettaboy
CMD /bin/bash
