\# 🚀 SaaS Stack Starter Kit



Template base para criação de SaaS composto por Spring Boot, Angular, Ionic e PostgreSQL via Docker.



\## 📁 Estrutura de Pastas



\- `/docker-compose.yml`: Infraestrutura do banco PostgreSQL local.

\- `/api`: Backend Spring Boot (Java 21, JPA, Web, Validation, Lombok).

\- `/web`: Dashboard Web em Angular (Standalone, SCSS, HttpClient).

\- `/mobile`: App Mobile em Ionic (Angular + Capacitor).



\## ⚡ Como Usar Este Template para um Novo Projeto



1\. Clone ou use o botão \*\*"Use this template"\*\* no GitHub.

2\. Altere o nome das pastas ou configurações no `pom.xml` (API) e `package.json` (Web/Mobile) para o nome do novo SaaS.

3\. Suba o banco local: `docker compose up -d`

4\. Inicie a API: `cd api \&\& ./mvnw spring-boot:run`

5\. Inicie a Web: `cd web \&\& ng serve`

6\. Inicie o Mobile: `cd mobile \&\& ionic serve`

