ARG VERSION=2.0.2

FROM debian:unstable AS build
RUN apt update && apt install -y build-essential wget git
RUN adduser --disabled-password dev
ARG VERSION
USER dev
ENV PATH="/home/dev/.nim/bin:$PATH"
# choosenim doesn't work on arm64 D:
#ENV CHOOSENIM_CHOOSE_VERSION=${NIM_VERSION}
#RUN curl https://nim-lang.org/choosenim/init.sh -sSf | sh -s -- -y && \
#    nimble refresh
RUN wget -nv https://nim-lang.org/download/nim-${VERSION}.tar.xz -O - \
    | tar -xJ -C /tmp
RUN cd /tmp/nim-${VERSION} \
    && ./build.sh \
    && bin/nim c koch \
    && ./koch boot -d:release \
    && ./koch tools \
    && ./install.sh /tmp/install-nim \
    && mv /tmp/install-nim/nim /home/dev/.nim \
    && cp ./bin/nimble /home/dev/.nim/bin/ \
    && nimble refresh

FROM scratch
COPY --from=build /home/dev/.nim /home/dev/.nim