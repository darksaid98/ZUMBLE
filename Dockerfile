FROM rust:1.67.0 as builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && apt install -y git bash make gcc linux-libc-dev patch musl musl-tools musl-dev openssl

RUN rustup target add x86_64-unknown-linux-musl

COPY . /zumble-build

WORKDIR /zumble-build

RUN openssl req -newkey rsa:2048 -new -nodes -x509 -days 3650 -keyout /key.pem -out /cert.pem -subj "/C=FR/ST=Paris/L=Paris/O=SoZ/CN=soz.zerator.com"

RUN cargo build --release --target x86_64-unknown-linux-musl && cp target/x86_64-unknown-linux-musl/release/zumble /zumble

FROM debian:buster-slim

ENV DEBIAN_FRONTEND noninteractive

RUN useradd -m -d /home/container -s /bin/bash container
RUN ln -s /home/container/ /nonexistent
ENV USER=container HOME=/home/container

COPY --from=builder /zumble /zumble
COPY --from=builder /cert.pem /cert.pem
COPY --from=builder /key.pem /key.pem

EXPOSE 64738/udp
EXPOSE 64738/tcp
EXPOSE 8080/tcp

ENV RUST_LOG=info

WORKDIR /home/container

COPY  ./entrypoint.sh /entrypoint.sh
CMD   ["/bin/bash", "/entrypoint.sh"]