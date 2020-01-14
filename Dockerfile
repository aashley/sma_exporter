FROM ubuntu

ARG sbfspot_version=3.6.0

RUN apt-get update && apt-get install -y \
        sqlite3 libsqlite3-dev \
        libboost-date-time-dev libboost-system-dev libboost-filesystem-dev libboost-regex-dev \
        ruby ruby-dev build-essential \
        libbluetooth-dev git curl

COPY . /srv/sma/
WORKDIR /srv/sma
RUN gem install bundler && \
        bundle update --bundler && \
        bundle install -j $(nproc)

RUN mkdir -p /srv/sbf /var/log/sbfspot.3 /usr/local/bin/sbfspot.3 && \
    curl -Lo /srv/sbf/sbf.tar.gz https://github.com/SBFspot/SBFspot/archive/V${sbfspot_version}.tar.gz && \
    tar -xf /srv/sbf/sbf.tar.gz -C /srv/sbf --strip-components=1 && \
    make -j$(nproc) -C /srv/sbf/SBFspot sqlite && \
    make -j$(nproc) -C /srv/sbf/SBFspot install_sqlite && \
    rm -rf /srv/sbf

COPY ./sbfspot/SBFspot.cfg /usr/local/bin/sbfspot.3/SBFspot.cfg

EXPOSE 5000
CMD SMA_SBFPATH=/usr/local/bin/sbfspot.3/SBFspot bundle exec unicorn -c unicorn.conf

