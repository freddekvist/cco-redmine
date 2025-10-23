# Use Ruby 3.3 base image
FROM ruby:3.3-slim-bookworm

# Explicitly set uid/gid to guarantee that it won't change in the future
RUN groupadd -r -g 999 redmine && useradd -r -g redmine -u 999 redmine

# Install system dependencies
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        build-essential \
        curl \
        git \
        nodejs \
        npm \
        postgresql-client \
        default-libmysqlclient-dev \
        libpq-dev \
        libsqlite3-dev \
        libxml2-dev \
        libxslt-dev \
        libyaml-dev \
        imagemagick \
        libmagickwand-dev \
        tzdata \
        pkgconf \
        xz-utils \
    ; \
    rm -rf /var/lib/apt/lists/*

# grab gosu for easy step-down from root
ENV GOSU_VERSION 1.19
RUN set -eux; \
    savedAptMark="$(apt-mark showmanual)"; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        gnupg \
    ; \
    rm -rf /var/lib/apt/lists/*; \
    \
    dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"; \
    wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch"; \
    wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc"; \
    export GNUPGHOME="$(mktemp -d)"; \
    gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4; \
    gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu; \
    gpgconf --kill all; \
    rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc; \
    \
    apt-mark auto '.*' > /dev/null; \
    apt-mark manual $savedAptMark > /dev/null; \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
    \
    chmod +x /usr/local/bin/gosu; \
    gosu --version; \
    gosu nobody true

ENV RAILS_ENV production

WORKDIR /usr/src/redmine

# https://github.com/docker-library/redmine/issues/138#issuecomment-438834176
# (bundler needs this for running as an arbitrary user)
ENV HOME /home/redmine
RUN set -eux; \
    [ ! -d "$HOME" ]; \
    mkdir -p "$HOME"; \
    chown redmine:redmine "$HOME"; \
    chmod 1777 "$HOME"

# Set Rails to log to STDOUT
ENV RAILS_LOG_TO_STDOUT true

# Copy application files
COPY . .

# Set up file permissions like official Redmine
RUN set -eux; \
    mkdir -p log public/assets public/plugin_assets sqlite tmp/pdf tmp/pids; \
    chown -R redmine:redmine ./; \
    # fix permissions for running as an arbitrary user
    chmod -R ugo=rwX config db sqlite; \
    find log tmp -type d -exec chmod 1777 '{}' +

# Install Ruby dependencies
RUN set -eux; \
    # Create bogus database.yml so all database adapters get installed
    echo '# temporary database.yml to force bundle install to include all adapters' > ./config/database.yml; \
    for adapter in mysql2 postgresql sqlserver sqlite3; do \
        echo "$adapter:" >> ./config/database.yml; \
        echo "  adapter: $adapter" >> ./config/database.yml; \
    done; \
    \
    # Install gems as redmine user
    gosu redmine bundle install --jobs "$(nproc)"; \
    rm ./config/database.yml; \
    \
    # fix permissions for running as an arbitrary user
    chmod -R ugo=rwX Gemfile.lock "$GEM_HOME"; \
    rm -rf ~redmine/.bundle

# Copy our entrypoint script
COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh

VOLUME /usr/src/redmine/files

ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 3000
CMD ["rails", "server", "-b", "0.0.0.0"]