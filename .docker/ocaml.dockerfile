FROM debian:unstable AS build
ARG VERSION
RUN apt update && apt install -y gcc build-essential curl unzip bubblewrap
RUN adduser --disabled-password dev
RUN echo | bash -c "sh <(curl -fsSL https://raw.githubusercontent.com/ocaml/opam/master/shell/install.sh)" && mkdir -p /home/dev/.opam/bin && mv /usr/local/bin/opam /home/dev/.opam/bin && chown -R dev /home/dev/.opam
USER dev
ENV PATH="/home/dev/.opam/bin:$PATH"
RUN opam init --compiler=${VERSION} --yes
RUN opam install ocamlsdl2 ocaml-lsp-server odoc ocamlformat utop --yes

FROM scratch
COPY --from=build /home/dev/.opam /home/dev/.opam
