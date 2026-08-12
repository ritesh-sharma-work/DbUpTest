# Database Migration Tool Recommendation & Additive Migration Strategy

This repository serves as a summary project and executable test harness for implementing database migrations using **DbUp** alongside an **Additive-Only Migration Strategy** enforced via **GitHub Actions CI**.

---

## 1. Database Migration Tool Recommendation

### Recommended Tool: DbUp

#### What is DbUp?
**DbUp** is an open-source .NET library that helps automate SQL Server database deployments by executing versioned SQL migration scripts.

Instead of comparing schemas or generating database changes automatically, DbUp simply executes SQL scripts that are explicitly created by developers and records each successfully executed migration in a journal table (`SchemaVersions`). This ensures that every migration is executed only once on each target database.

> 📖 **Official Documentation**: [https://dbup.readthedocs.io/en/latest/](https://dbup.readthedocs.io/en/latest/)

---

### Why DbUp is Recommended
DbUp aligns well with the current architecture and project requirements.

#### Key Benefits
* **Excellent fit for .NET applications**: Native .NET integration as a lightweight console runner or library.
* **Supports Database-First development**: Perfect for teams managing pre-existing or complex schemas.
* **Works seamlessly with existing legacy databases**: No need to redesign existing database structures.
* **Uses plain SQL scripts**: Complete control over raw T-SQL without ORM abstraction limitations.
* **Automatically tracks applied migrations**: Uses a simple `SchemaVersions` table to track execution history.
* **Git-friendly**: Migration scripts live directly alongside application code in source control.
* **Straightforward CI/CD integration**: Executes as a lightweight `.NET` CLI step in GitHub Actions, Azure DevOps, or Jenkins.
* **Supports multiple database catalogs**: Can run against primary, reporting, or auxiliary databases easily.
* **Does not require ownership/recreation of existing schema**: Preserves database identity and security roles.
* **Enables Additive-Only Migration Strategy**: Full support for zero-downtime database deployment patterns.

---

## 2. Additive-Only Migration Strategy

One of the primary project requirements is that database migrations **must be additive only**.

DbUp itself executes the SQL scripts that developers provide. Therefore, enforcing an additive-only policy is achieved through development standards and CI/CD validation.

### Policy Rules

| Allowed Operations (Additive) | Restricted Operations (Destructive) |
| :--- | :--- |
| ✅ `CREATE TABLE` | ❌ `DROP TABLE` |
| ✅ `ADD COLUMN` | ❌ `DROP COLUMN` |
| ✅ `CREATE INDEX` | ❌ `DROP PROCEDURE` / `DROP VIEW` |
| ✅ `CREATE PROCEDURE` | ❌ Destructive `ALTER` statements |
| ✅ `CREATE VIEW` | ❌ `TRUNCATE TABLE` |
| ✅ Insert / Seed Reference Data | ❌ Modifications impacting existing consumers |

This approach minimizes deployment risk while ensuring backward compatibility with existing applications and integrations.

---

## 3. Proposed Migration Workflow

```
      Developer
          │
          ▼
Create Versioned SQL Migration
    (V001, V002, V003...)
          │
          ▼
Commit to Git Repository
          │
          ▼
     Pull Request
          │
          ▼
     CI Validation
──────────────────────────────
✓ CREATE
✓ ADD
✓ CREATE INDEX

✗ DROP
✗ Destructive ALTER
✗ Other Breaking Changes
──────────────────────────────
          │
          ▼
Code Review & Approval
          │
          ▼
CI Executes DbUp
          │
          ▼
 Target Database
```

---

## 4. Alternative Option: Flyway

As an alternative, **Flyway** is also a mature and widely adopted database migration tool.

### Flyway Features
* Versioned SQL migrations
* Migration checksums
* Schema history tracking
* Baseline support for existing databases
* Strong CI/CD integration
* Multi-platform support

*Flyway is a suitable enterprise-grade alternative, particularly for organizations managing databases across multiple technology stacks.*

However, given the current environment, existing .NET ecosystem, and database-first architecture, **DbUp is considered the preferred solution** due to its simplicity, flexibility, and seamless integration with .NET applications.

---

## 5. Repository Structure & Sample Project

```
DbUp/
├── .github/
│   ├── scripts/
│   │   └── validate-migrations.ps1   # PowerShell policy validator for CI/CD
│   └── workflows/
│       └── ci.yml                    # GitHub Actions CI workflow
├── scripts/
│   ├── Script0001 - Create Initial Tables.sql
│   ├── Script0002 - Add Customer Phone and Stored Procedure.sql
│   └── samples/
│       └── Script0003_FAIL_DropTableTest.sql.sample
├── DbUp.csproj                        # Fixed .NET 9 Console App project
├── Program.cs                         # DbUp runner execution logic
└── README.md                          # Recommendation & guide
```

---

## 6. How to Test this Flow

### Local Testing

1. **Build the Console App**:
   ```bash
   dotnet build
   ```

2. **Run Policy Validator Locally**:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\.github\scripts\validate-migrations.ps1 -ScriptsFolder .\scripts
   ```

3. **Run Migrations Locally**:
   ```bash
   dotnet run -- "Server=(localdb)\mssqllocaldb;Database=DbUpTestDb;Trusted_Connection=True;TrustServerCertificate=True;"
   ```

---

### GitHub Testing

1. **Commit and Push to GitHub**:
   ```bash
   git add .
   git commit -m "Configure DbUp migration runner and CI validation flow"
   git push origin main
   ```

2. **Test PR Validation (Success Case)**:
   - Create a new branch: `git checkout -b feature/add-new-table`
   - Add a valid SQL script in `scripts/Script0003 - Create Products Table.sql`
   - Commit, push, and open a Pull Request.
   - **Result**: The `Validate Additive-Only Policy` and `Build & Test Migration Runner` jobs in GitHub Actions will pass.

3. **Test PR Validation (Failure Case)**:
   - Create a test branch with a script containing `DROP TABLE [dbo].[Customers];`.
   - Commit, push, and open a Pull Request.
   - **Result**: The CI check will fail instantly on line matching, preventing destructive SQL from reaching `main`.

---

### Configuring Production Database Connection String in GitHub

To enable automatic production database migrations when pushing to `main`:

1. Open your GitHub Repository in your browser.
2. Go to **Settings** ➔ **Secrets and variables** ➔ **Actions**.
3. Click **New repository secret**.
4. Set **Name**: `PROD_DB_CONNECTION_STRING`.
5. Set **Value**: Your target database connection string, e.g.:
   `Server=your-db-server.database.windows.net;Database=ProdDb;User Id=dbadmin;Password=YourPassword;Encrypt=True;`
6. Click **Add secret**.

Regarding our DbUp migration setup, should developers write SQL migration scripts manually, or would you prefer using an ORM (EF Core) to auto-generate the .sql files from code before deploying them via DbUp?

Please let us know your preferred approach for managing schema changes.