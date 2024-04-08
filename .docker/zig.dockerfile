FROM debian:unstable AS build
ARG VERSION
RUN apt update && apt install -y wget adduser
RUN adduser --disabled-password dev
USER dev
RUN mkdir /home/dev/.zig \
    && wget -nv https://ziglang.org/builds/zig-linux-$(uname -m)-${VERSION}.tar.xz -O - \
    | tar --strip-components=1 -C ~/.zig -xJ

FROM scratch
COPY --from=build /home/dev/.zig /home/dev/.zig
