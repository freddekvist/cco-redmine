# Använd nyare Redmine som matchar din Rails-version
FROM redmine:6.0

# Kopiera dina anpassade filer - explicit kopiering av undermappar
# Först skapa målmapparna
RUN mkdir -p /usr/src/redmine/themes/cco /usr/src/redmine/plugins/redmine_contacts

# Kopiera tema och plugin specifikt
COPY themes/cco/ /usr/src/redmine/themes/cco/
COPY plugins/redmine_contacts/ /usr/src/redmine/plugins/redmine_contacts/

# Kopiera config-filer som finns
COPY config/database.yml /usr/src/redmine/config/database.yml

# Sätt rätt ägare och permissions
USER root
RUN chown -R redmine:redmine /usr/src/redmine/themes/cco/ /usr/src/redmine/plugins/redmine_contacts/ /usr/src/redmine/config/
RUN chmod -R 755 /usr/src/redmine/themes/cco/ /usr/src/redmine/plugins/redmine_contacts/

# Validera att filerna kopierades korrekt
RUN if [ -d "/usr/src/redmine/themes/cco" ]; then \
        echo "CCO theme found"; \
    else \
        echo "CCO theme NOT found"; \
    fi
RUN if [ -d "/usr/src/redmine/plugins/redmine_contacts" ]; then \
        echo "Redmine contacts plugin found"; \
    else \
        echo "Redmine contacts plugin NOT found"; \
    fi

# Debug - visa vad som finns
RUN echo "=== THEMES ===" && ls -la /usr/src/redmine/themes/
RUN echo "=== CCO THEME ===" && ls -la /usr/src/redmine/themes/cco/ || echo "CCO theme not found"
RUN echo "=== PLUGINS ===" && ls -la /usr/src/redmine/plugins/
RUN echo "=== REDMINE_CONTACTS PLUGIN ===" && ls -la /usr/src/redmine/plugins/redmine_contacts/ || echo "redmine_contacts plugin not found"

USER redmine

# Installera plugin-gems och kör migrations
RUN bundle check || bundle install
RUN bundle exec rake redmine:plugins:migrate RAILS_ENV=production || true

# Standard Redmine entrypoint och kommando
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["rails", "server", "-b", "0.0.0.0"]