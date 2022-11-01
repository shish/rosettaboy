FROM debian:unstable
RUN apt update
RUN apt install -y \
    build-essential linux-perf valgrind vim git libsdl2-dev \
    cmake clang-format-14 \
    golang \
    python3 python3-venv black \
    php-cli \
    rust-all

ARG USER_ID
ARG GROUP_ID
RUN addgroup --gid $GROUP_ID user || true
RUN adduser --disabled-password --gecos '' --uid $USER_ID --gid $GROUP_ID user
USER user

WORKDIR /home/dev
CMD /bin/bash
