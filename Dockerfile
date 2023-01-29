FROM rust:1.67.0 as builder

ENV DEBIAN_FRONTEND=noninteractive

## packages
RUN apt update && apt install -y git bash make gcc linux-libc-dev patch musl musl-tools musl-dev openssl

RUN rustup target add x86_64-unknown-linux-musl

## building
COPY . /zumble-build

WORKDIR /zumble-build

RUN openssl req -newkey rsa:2048 -new -nodes -x509 -days 3650 -keyout /key.pem -out /cert.pem -subj "/C=FR/ST=Paris/L=Paris/O=SoZ/CN=soz.zerator.com"

RUN cargo build --release --target x86_64-unknown-linux-musl && cp target/x86_64-unknown-linux-musl/release/zumble /zumble

## launching
FROM debian:buster-slim

ENV DEBIAN_FRONTEND noninteractive

## add container user
RUN useradd -m -d /home/container -s /bin/bash container
RUN ln -s /home/container/ /nonexistent
ENV USER=container HOME=/home/container

## import built files
COPY --from=builder /zumble /zumble
COPY --from=builder /cert.pem /cert.pem
COPY --from=builder /key.pem /key.pem

EXPOSE 64738/udp
EXPOSE 64738/tcp
EXPOSE 8080/tcp

ENV RUST_LOG=info

RUN cp /zumble /home/container/zumble

## update base packages
RUN apt update \
 && apt upgrade -y

## install dependencies
RUN apt install -y iproute2

WORKDIR /home/container

COPY ./entrypoint.sh /entrypoint.sh
CMD ["/bin/bash", "/entrypoint.sh"]