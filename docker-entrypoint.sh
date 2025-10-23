#!/usr/bin/env bash
set -Eeo pipefail

# Function to check if we're likely running Redmine
isLikelyRedmine=
case "${1:-}" in
	rails | rake | ruby )
		isLikelyRedmine=1
		;;
	* )
		if [ -f './config.ru' ] && [ -f './config/environment.rb' ]; then
			isLikelyRedmine=1
		fi
		;;
esac

_fix_permissions() {
	local dirs=( config log public/assets public/plugin_assets tmp ) args=()
	if [ "$(id -u)" = '0' ]; then
		args+=( ${args[@]:+,} '(' '!' -user redmine -exec chown redmine:redmine '{}' + ')' )
		local filesOwnerMode
		filesOwnerMode="$(stat -c '%U:%a' files)"
		if [ "$filesOwnerMode" != 'redmine:755' ]; then
			dirs+=( files )
		fi
	fi
	# directories 755, files 644:
	args+=( ${args[@]:+,} '(' -type d '!' -perm 755 -exec sh -c 'chmod 755 "$@" 2>/dev/null || :' -- '{}' + ')' )
	args+=( ${args[@]:+,} '(' -type f '!' -perm 644 -exec sh -c 'chmod 644 "$@" 2>/dev/null || :' -- '{}' + ')' )
	find "${dirs[@]}" "${args[@]}"
}

# allow the container to be started with `--user`
if [ -n "$isLikelyRedmine" ] && [ "$(id -u)" = '0' ]; then
	_fix_permissions
	exec gosu redmine "$BASH_SOURCE" "$@"
fi

if [ -n "$isLikelyRedmine" ]; then
	_fix_permissions
	
	# Generate database.yml if it doesn't exist and DATABASE_URL is provided
	if [ ! -f './config/database.yml' ] && [ -n "${DATABASE_URL:-}" ]; then
		echo "production:" > config/database.yml
		echo "  url: $DATABASE_URL" >> config/database.yml
	fi

	# install additional gems for Gemfile.local and plugins
	bundle check || bundle install

	# Set SECRET_KEY_BASE
	if [ -z "${SECRET_KEY_BASE:-}" ]; then
		if [ ! -f config/initializers/secret_token.rb ]; then
			echo >&2
			echo >&2 'warning: no SECRET_KEY_BASE set; running `rake generate_secret_token`'
			echo >&2
			rake generate_secret_token
		fi
	fi

	# Run database migrations
	if [ "$1" != 'rake' ] && [ -z "${REDMINE_NO_DB_MIGRATE:-}" ]; then
		rake db:migrate
	fi

	# Load default data if requested
	if [ -n "${REDMINE_LOAD_DEFAULT_DATA:-}" ]; then
		rake redmine:load_default_data REDMINE_LANG="${REDMINE_LANG:-en}"
	fi

	# remove PID file to enable restarting the container
	rm -f tmp/pids/server.pid
fi

exec "$@"