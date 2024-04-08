FROM debian:unstable AS build
ARG VERSION
RUN apt update && apt install -y wget adduser
RUN adduser --disabled-password dev
USER dev
RUN mkdir /home/dev/.go \
    && wget -nv https://go.dev/dl/go${VERSION}.linux-$(dpkg --print-architecture).tar.gz -O - \
    | tar --strip-components=1 -xz -C /home/dev/.go

FROM scratch
COPY --from=build /home/dev/.go /home/dev/.go
