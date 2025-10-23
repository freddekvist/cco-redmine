# Använd nyare Redmine som matchar din Rails-version
FROM redmine:6.0

# Kopiera dina anpassade filer
COPY themes/ /usr/src/redmine/themes/
COPY plugins/ /usr/src/redmine/plugins/

# Kopiera config-filer som finns
COPY config/database.yml /usr/src/redmine/config/database.yml

# Sätt rätt ägare och permissions
USER root
RUN chown -R redmine:redmine /usr/src/redmine/themes/ /usr/src/redmine/plugins/ /usr/src/redmine/config/
RUN chmod -R 755 /usr/src/redmine/themes/ /usr/src/redmine/plugins/

# Debug - visa vad som finns
RUN echo "=== THEMES ===" && ls -la /usr/src/redmine/themes/
RUN echo "=== PLUGINS ===" && ls -la /usr/src/redmine/plugins/

USER redmine

# Installera plugin-gems och kör migrations
RUN bundle check || bundle install
RUN bundle exec rake redmine:plugins:migrate RAILS_ENV=production || true

# Standard Redmine entrypoint och kommando
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["rails", "server", "-b", "0.0.0.0"]