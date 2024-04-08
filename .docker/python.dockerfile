FROM debian:unstable AS build
ARG VERSION
RUN apt update && apt install -y wget adduser git
RUN adduser --disabled-password dev
RUN apt-get install -y --no-install-recommends \
    make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev \
    libsqlite3-dev wget curl llvm libncurses5-dev xz-utils tk-dev \
    libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev \
    && apt-get install -y mecab-ipadic-utf8
USER dev
ENV PYENV_ROOT="/home/dev/.pyenv"
ENV PATH="/home/dev/.pyenv/shims:/home/dev/.pyenv/bin:$PATH"
RUN git clone --depth=1 https://github.com/yyuu/pyenv /home/dev/.pyenv \
    && pyenv install ${VERSION} \
	&& pyenv global ${VERSION} \
	&& pyenv rehash

FROM scratch
COPY --from=build /home/dev/.pyenv /home/dev/.pyenv
