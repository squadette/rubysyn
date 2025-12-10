FROM ubuntu:20.04

ENV DEBIAN_FRONTEND noninteractive

# All actions which might affect image size are squeezed
RUN apt-get update && apt-get install -y curl

ENV PACKAGES  "\
    build-essential \
    gpg gpg-agent \
    gawk autoconf automake bison libffi-dev libgdbm-dev libncurses5-dev libsqlite3-dev libtool libyaml-dev pkg-config sqlite3 zlib1g-dev libgmp-dev libreadline-dev libssl-dev \
    "

# Install dependencies and clean documentation
RUN apt-get update && \
    apt-get --allow-unauthenticated install \
            --no-install-recommends -y \
            $PACKAGES

# Install RVM
RUN curl -sSL https://rvm.io/mpapis.asc https://rvm.io/pkuczynski.asc | gpg --import -

RUN curl -L https://get.rvm.io | rvm_path=/var/rubysyn/rvm bash -s 1.29.12

RUN echo "source /var/rubysyn/rvm/scripts/rvm" >> /etc/bash.bashrc

WORKDIR /var/rubysyn/src
