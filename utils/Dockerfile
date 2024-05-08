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


# Install C/C++ tools
USER root
RUN apt update && apt install -y cmake clang clang-format-14 libfmt-dev

# Install Go tools
COPY --from=shish2k/rosettaboy-devkit-go:1.22.2 --chown=${USER_ID}:${GROUP_ID} /home/dev/.go /home/dev/.go
ENV PATH="/home/dev/.go/bin:$PATH"

# Install Nim tools
COPY --from=shish2k/rosettaboy-devkit-nim:2.0.2 --chown=${USER_ID}:${GROUP_ID} /home/dev/.nim /home/dev/.nim
ENV PATH="/home/dev/.nim/bin:$PATH"

# Install PHP tools
COPY --from=shish2k/rosettaboy-devkit-php:8.3.4 --chown=${USER_ID}:${GROUP_ID} /home/dev/.php /home/dev/.php
ENV PATH="/home/dev/.php/bin:$PATH"

# Install Python tools
COPY --from=shish2k/rosettaboy-devkit-python:3.12.2 --chown=${USER_ID}:${GROUP_ID} /home/dev/.pyenv /home/dev/.pyenv
ENV PYENV_ROOT="/home/dev/.pyenv"
ENV PATH="/home/dev/.pyenv/shims:/home/dev/.pyenv/bin:$PATH"

# Install Rust tools
COPY --from=shish2k/rosettaboy-devkit-rust:1.77.1 --chown=${USER_ID}:${GROUP_ID} /home/dev/.rustup /home/dev/.rustup
COPY --from=shish2k/rosettaboy-devkit-rust:1.77.1 --chown=${USER_ID}:${GROUP_ID} /home/dev/.cargo /home/dev/.cargo
ENV PATH="/home/dev/.cargo/bin:$PATH"

# Install Zig tools
COPY --from=shish2k/rosettaboy-devkit-zig:0.12.0 --chown=${USER_ID}:${GROUP_ID} /home/dev/.zig /home/dev/.zig
ENV PATH="/home/dev/.zig:$PATH"

# Get ready to go
USER dev
WORKDIR /home/dev/rosettaboy
CMD /bin/bash
