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

3. **Miljövariabler:**
   Lägg till följande miljövariabler i Coolify:
   ```
   RAILS_ENV=production
   SECRET_KEY_BASE=<generera en stark nyckel>
   DATABASE_URL=<din databas-URL>
   ```

4. **Databas:**
   - Skapa en PostgreSQL-databas i Coolify
   - Använd databasanslutningen som DATABASE_URL

5. **Volumes (om nödvändigt):**
   - `/app/files` för filuppladdningar
   - `/app/log` för loggar

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