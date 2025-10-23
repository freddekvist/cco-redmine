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

# Copy Gemfile and Gemfile.lock first to leverage Docker layer caching
COPY Gemfile Gemfile.lock ./

# Install Ruby dependencies
RUN bundle config set --local deployment 'true' && \
    bundle config set --local without 'development test' && \
    bundle install

# Copy package.json and yarn.lock for JS dependencies
COPY package.json yarn.lock ./

# Install JavaScript dependencies
RUN npm install -g yarn && yarn install --frozen-lockfile

# Copy the application code
COPY . .

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