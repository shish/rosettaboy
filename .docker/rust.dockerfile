FROM debian:unstable AS build
ARG VERSION
RUN apt update && apt install -y adduser wget
RUN adduser --disabled-password dev
USER dev
ENV PATH="/home/dev/.cargo/bin:$PATH"
RUN wget -nv -qO - https://sh.rustup.rs | sh -s -- --default-toolchain ${VERSION} -y \
    && cargo search foo
# Cranelift is only in nightly
RUN rustup toolchain install nightly \
    && rustup component add rustc-codegen-cranelift-preview --toolchain nightly

FROM scratch
COPY --from=build /home/dev/.rustup /home/dev/.rustup
COPY --from=build /home/dev/.cargo /home/dev/.cargo
