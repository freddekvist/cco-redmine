# Använd officiella Redmine som bas
FROM redmine:5.1

# Kopiera bara dina anpassade filer
COPY themes/ themes/
COPY plugins/ plugins/

# Om du har anpassade configs
COPY config/additional_environment.rb config/additional_environment.rb

# Sätt rätt ägare
USER root
RUN chown -R redmine:redmine themes/ plugins/ config/
USER redmine

# Installera eventuella extra gems från plugins
RUN bundle install

# Standard Redmine entrypoint och kommando
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["rails", "server", "-b", "0.0.0.0"]