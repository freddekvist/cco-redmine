# Use Ruby 3.3 base image
FROM ruby:3.3-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    git \
    nodejs \
    npm \
    postgresql-client \
    libpq-dev \
    imagemagick \
    libmagickwand-dev \
    tzdata \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy Gemfile and placeholder Gemfile.lock
COPY Gemfile Gemfile.lock* ./

# Install Ruby dependencies
RUN bundle config set --local without 'development test' && \
    bundle install && \
    bundle lock --add-platform ruby && \
    bundle lock --add-platform x86_64-linux

# Copy package.json for JS dependencies
COPY package.json ./

# Install JavaScript dependencies
RUN npm install -g yarn && yarn install

# Copy the application code
COPY . .

# Ensure database configuration is available
COPY config/database.yml config/database.yml

# Precompile assets for production
RUN RAILS_ENV=production bundle exec rails assets:precompile

# Create a non-root user
RUN adduser --disabled-password --gecos '' appuser && \
    chown -R appuser:appuser /app
USER appuser

# Expose port
EXPOSE 3000

# Start the Rails server
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "3000"]