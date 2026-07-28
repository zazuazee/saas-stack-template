# 🚀 SaaS Stack Template

Template base (Boilerplate) para criação de aplicações SaaS modernas, robustas e escaláveis.

## 🛠️ Tecnologias Utilizadas

* **Backend:** Java (Spring Boot) + Hibernate / JPA
* **Banco de Dados:** PostgreSQL (via Docker)
* **Web Frontend:** Angular CLI
* **Mobile App:** Ionic + Capacitor (Angular Standalone Components)
* **Ambiente & Deploy:** Docker Compose + Dotenv (`.env`)

---

## 📁 Estrutura do Projeto

```text
├── api/                  # Backend Spring Boot
├── web/                  # Frontend Web Angular
├── mobile/               # App Mobile Ionic
├── docker-compose.yml    # Orquestração do Banco PostgreSQL
├── .env.example          # Modelo de variáveis de ambiente
└── README.md
```

---

## ⚙️ Passo a Passo para Configuração Inicial

**1. Duplicar o arquivo de variáveis de ambiente**

Na raiz do projeto, crie o arquivo `.env` a partir do modelo `.env.example`:

```powershell
Copy-Item .env.example .env
```

Edite o arquivo `.env` para ajustar os nomes e parâmetros do projeto atual (no exemplo abaixo, o nome do projeto é `taskflow`):

```env
APP_NAME=taskflow-api
DB_CONTAINER_NAME=taskflow-postgres
DB_NAME=taskflow_db
DB_USER=postgres
DB_PASSWORD=postgrespassword
DB_PORT=5432
DB_HOST=localhost
```

---

## 🚀 Como Rodar o Projeto Localmente

### 1️⃣ Banco de Dados (PostgreSQL)
Certifique-se de estar com o Docker rodando e execute na raiz:
```powershell
docker compose up -d
```

### 2️⃣ API (Spring Boot)
Navegue até a pasta `api` e inicie o servidor (ele carregará o `.env` e conectará ao banco automaticamente):
```powershell
cd api
./mvnw spring-boot:run
```
> **URL da API:** http://localhost:8080

### 3️⃣ Web (Angular)
Em outro terminal, acesse a pasta `web` e execute:
```powershell
cd web
ng serve
```
> **URL Web:** http://localhost:4200

### 4️⃣ Mobile (Ionic)
Em outro terminal, acesse a pasta `mobile` e execute:
```powershell
cd mobile
ionic serve
```
> **URL Mobile:** http://localhost:8100

---

## ⚠️ Observação sobre criação de Submódulos

Para evitar que o Git crie as pastas `web` ou `mobile` como submódulos/atalhos ao regerar componentes, sempre utilize as flags de pular inicialização de repositório git:

* **Angular:** `ng new web --skip-git`
* **Ionic:** `ionic start mobile blank --type=angular --capacitor --no-git`