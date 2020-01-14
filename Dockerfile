FROM ubuntu:18.04

ARG sbfspot_version=3.6.0

RUN apt-get update && apt-get install -y \
        git \
        libbluetooth3 \
        libboost-date-time1.65.1 \
        libboost-system1.65.1 \
        libboost-filesystem1.65.1 \
        libboost-regex1.65.1 \
        libsqlite3-0 \
        sqlite3 \
        ruby \
        --no-install-recommends && rm -r /var/lib/apt/lists/*

COPY . /srv/sma/
WORKDIR /srv/sma

RUN set -xe \
    && buildDeps=" \
        build-essential \
        curl \
        libbluetooth-dev \
        libboost-date-time-dev \
        libboost-system-dev \
        libboost-filesystem-dev \
        libboost-regex-dev \
        libsqlite3-dev \
        ruby-dev \
    " \
    && apt-get update \
    && apt-get install -y $buildDeps --no-install-recommends \
    && rm -rf /var/lib/apt/lists/* \
    && gem install bundler \
    && bundle update --bundler \
    && bundle install -j $(nproc) \
    && mkdir -p /srv/sbf /var/log/sbfspot.3 /usr/local/bin/sbfspot.3 \
    && curl -Lo /srv/sbf/sbf.tar.gz https://github.com/SBFspot/SBFspot/archive/V${sbfspot_version}.tar.gz \
    && tar -xf /srv/sbf/sbf.tar.gz -C /srv/sbf --strip-components=1 \
    && make -j$(nproc) -C /srv/sbf/SBFspot sqlite \
    && make -j$(nproc) -C /srv/sbf/SBFspot install_sqlite \
    && rm -rf /srv/sbf \
    && apt-get purge -y --auto-remove \
        -o APT::AutoRemove::RecommendsImportant=false \
        -o APT::AutoRemove::SuggestsImportant=false \
        $buildDeps

COPY ./sbfspot/SBFspot.cfg /usr/local/bin/sbfspot.3/SBFspot.cfg

EXPOSE 5000
CMD SMA_SBFPATH=/usr/local/bin/sbfspot.3/SBFspot bundle exec unicorn -c unicorn.conf

