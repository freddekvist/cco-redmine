# Använd nyare Redmine som matchar din Rails-version
FROM redmine:6.0

# Kopiera bara dina anpassade filer som finns
COPY themes/ themes/
COPY plugins/ plugins/

# Kopiera config-filer som finns
COPY config/database.yml config/database.yml

# Sätt rätt ägare
USER root
RUN chown -R redmine:redmine themes/ plugins/ config/
USER redmine

# Installera eventuella extra gems från plugins (hoppa över om inga nya gems)
RUN bundle check || bundle install

# Standard Redmine entrypoint och kommando
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["rails", "server", "-b", "0.0.0.0"]