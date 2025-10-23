# CCO Redmine

En anpassad Redmine-installation för CCO.

## Deployment med Coolify

### Förutsättningar
- Coolify-instans
- GitHub repository (detta repo)

### Steg för deployment:

1. **Skapa nytt projekt i Coolify:**
   - Logga in på din Coolify-instans
   - Klicka på "New Resource" → "Application"
   - Välj "Git Repository"

2. **Konfigurera repository:**
   - Repository URL: `https://github.com/freddekvist/cco-redmine`
   - Branch: `main`
   - Build Pack: `Docker`

3. **Databas (automatisk setup):**
   - Coolify kommer automatiskt att detektera att detta är en Rails-app
   - En PostgreSQL-databas skapas automatiskt
   - `DATABASE_URL` miljövariabel sätts automatiskt

4. **Miljövariabler (lägg till manuellt):**
   ```
   RAILS_ENV=production
   SECRET_KEY_BASE=<generera en stark nyckel>
   RAILS_SERVE_STATIC_FILES=true
   RAILS_LOG_TO_STDOUT=true
   ```

5. **Första deployment:**
   - Efter första deployment, kör databasmigrationer via Coolify-terminalen:
   ```bash
   bundle exec rails db:migrate RAILS_ENV=production
   bundle exec rails redmine:load_default_data RAILS_ENV=production REDMINE_LANG=sv
   ```

### Generera SECRET_KEY_BASE

Kör följande kommando för att generera en stark hemlig nyckel:
```bash
openssl rand -hex 64
```

### Lokal utveckling

```bash
# Installera dependencies
bundle install

# Kör med Docker
docker-compose up --build
```

### Produktionsinställningar

Se `config/environments/production.rb` för produktionsinställningar.
Viktiga saker att konfigurera:
- Databas
- E-postinställningar
- SSL-certifikat
- Domännamn

## Support

För support, kontakta CCO IT-avdelningen.