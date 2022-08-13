FROM debian:unstable
RUN apt update
RUN apt install -y \
    build-essential linux-perf valgrind vim git libsdl2-dev \
    cmake clang-format-12 \
    golang \
    python3 python3-venv black \
    php-cli \
    rust-all
WORKDIR /home/dev
CMD /bin/bash
