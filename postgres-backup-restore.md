# PostgreSQL Backup & Restore Guide

A practical, copy‑paste friendly reference for backing up and restoring PostgreSQL databases. Works for PostgreSQL 12+ unless noted.

---

## 🚀 Quick Start

### Backup a database (custom format)
```bash
pg_dump -U <user> -F c -b -v -f "/backups/<db>_$(date +%Y%m%d).backup" <db>
```

### Restore to an existing database
```bash
pg_restore -U <user> -d <db> -v "/backups/<db>_YYYYMMDD.backup"
```

### Restore to a **new** database
```bash
createdb -U <user> <newdb>
pg_restore -U <user> -d <newdb> -v "/backups/<db>_YYYYMMDD.backup"
```

---

## 📦 What to Use (and When)

- **Logical backups** (pg_dump / pg_restore): portable, great for migrations and selective restores (schemas/tables).  
- **Physical backups** (pg_basebackup + WAL): best for large DBs and **point‑in‑time recovery (PITR)**.  
- PostgreSQL does **not** have `BACKUP DATABASE ...` SQL commands (that’s SQL Server). Use CLI tools.

---

## 🔐 Prerequisites

- PostgreSQL client binaries installed (`pg_dump`, `pg_restore`, `psql`, `pg_basebackup`).  
- A superuser or a role with sufficient privileges for objects you’re backing up.  
- Storage with enough free space and (ideally) off‑host/off‑site replication of backups.

---

## 🧰 Logical Backups (pg_dump)

### 1) Entire database (recommended format)
```bash
pg_dump -U <user> -F c -b -v -f "/backups/<db>_$(date +%Y%m%d).backup" <db>
```
- `-F c`: custom format (enables parallel restore, compression).
- `-b`: include large objects (BLOBs).

### 2) All databases on the server
```bash
pg_dumpall -U <user> -f "/backups/all_$(date +%Y%m%d).sql"
```
> Tip: Combine with separate per‑DB dumps if you want parallel restores later.

### 3) Single schema
```bash
pg_dump -U <user> -F c -n <schema> -f "/backups/<db>_<schema>_$(date +%Y%m%d).backup" <db>
```

### 4) Single table
```bash
pg_dump -U <user> -t <schema>.<table> -F c -f "/backups/<db>_<table>_$(date +%Y%m%d).backup" <db>
```

### 5) Globals (roles & tablespaces)
```bash
pg_dumpall -U <user> --globals-only -f "/backups/globals_$(date +%Y%m%d).sql"
```

### 6) Parallel dump (speed on large DBs)
```bash
pg_dump -U <user> -F d -j 4 -f "/backups/<db>_dir_$(date +%Y%m%d)" <db>
```
> Directory format (`-F d`) supports parallel dump/restore with `-j`.

### 7) Compression ideas
- Custom format already compresses. For directory/SQL:
```bash
pg_dump -U <user> <db> | gzip > "/backups/<db>_$(date +%Y%m%d).sql.gz"
```

---

## ♻️ Restoring (pg_restore / psql)

### 1) From custom format (`.backup`)
```bash
# Recreate schema only (dry run structure)
pg_restore -U <user> -d <db> -s -v "/backups/<db>.backup"

# Data only
pg_restore -U <user> -d <db> -a -v "/backups/<db>.backup"

# Full restore (structure + data)
pg_restore -U <user> -d <db> -v "/backups/<db>.backup"
```

### 2) From directory format
```bash
pg_restore -U <user> -d <db> -j 4 -v "/backups/<db>_dir_YYYYMMDD"
```

### 3) From plain SQL
```bash
psql -U <user> -d <db> -f "/backups/<db>.sql"
```

### 4) Restore a single table
If backed up with `-t`:
```bash
pg_restore -U <user> -d <db> -t <schema>.<table> "/backups/<db>_<table>.backup"
```

### 5) Restore globals
```bash
psql -U <user> -f "/backups/globals_YYYYMMDD.sql" postgres
```

### Common flags
- `--clean`: drop and recreate objects.
- `--if-exists`: avoid errors when dropping missing objects.
- `--no-owner`: useful when restoring as a non‑superuser.
- `--schema` / `--table`: scope the restore.

---

## ⏱️ Scheduling

### Linux (cron) — daily at 02:00
```bash
0 2 * * * pg_dump -U <user> -F c -b -f "/backups/<db>_$(date +\%Y\%m\%d).backup" <db> && pg_dumpall -U <user> --globals-only -f "/backups/globals_$(date +\%Y\%m\%d).sql" && find /backups -type f -mtime +14 -delete
```

### Windows (Task Scheduler) — daily at 02:00 (PowerShell)
```powershell
$dt = Get-Date -Format "yyyyMMdd"
& "C:\Program Files\PostgreSQL\16\bin\pg_dump.exe" -U <user> -F c -b -f "C:\backups\<db>_$dt.backup" <db>
& "C:\Program Files\PostgreSQL\16\bin\pg_dumpall.exe" -U <user> --globals-only -f "C:\backups\globals_$dt.sql"
Get-ChildItem "C:\backups\*" | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-14) } | Remove-Item
```

> Store credentials safely (e.g., `.pgpass` on Linux/macOS, `%APPDATA%\postgresql\pgpass.conf` on Windows).

---

## 🧭 Point‑in‑Time Recovery (Physical Backups)

### 1) Enable WAL archiving (on the primary)
Edit `postgresql.conf` (reload/restart after changes):
```conf
archive_mode = on
archive_command = 'test ! -f /wal-archive/%f && cp %p /wal-archive/%f'
wal_level = replica
```
Ensure `/wal-archive` is durable storage.

### 2) Take a base backup
```bash
pg_basebackup -U <replication_user> -D /basebackup/$(date +%Y%m%d) -Ft -X stream -P
```
- `-Ft`: tar output (use `-Fp` for plain directory).

### 3) Recover to a point in time
On the target data directory (stopped cluster):
```bash
# PostgreSQL 12–14: recovery.conf (older) or GUCs in postgresql.conf (newer)
# PostgreSQL 15+: use the new GUC names
# Example with recovery.signal file:
touch $PGDATA/recovery.signal
echo "restore_command = 'cp /wal-archive/%f %p'" >> $PGDATA/postgresql.conf
echo "recovery_target_time = '2025-10-19 21:30:00+00'" >> $PGDATA/postgresql.conf
```
Start PostgreSQL and it will replay WAL up to the target.

> PITR is advanced: test thoroughly before relying on it in production.

---

## ☁️ Off‑Site / Cloud Storage

### AWS S3
```bash
aws s3 cp "/backups/<db>_YYYYMMDD.backup" "s3://your-bucket/path/"
```

### Google Cloud Storage
```bash
gsutil cp "/backups/<db>_YYYYMMDD.backup" "gs://your-bucket/path/"
```

### Azure Blob Storage
```bash
az storage blob upload --container-name backups --file "/backups/<db>_YYYYMMDD.backup" --name "<db>_YYYYMMDD.backup"
```

> Encrypt at rest (server‑side or client‑side) and restrict access via IAM.

---

## ✅ Verification & Health Checks

- **List contents of a backup** (without restoring):
```bash
pg_restore -l "/backups/<db>.backup"
```

- **Checksum** the file after transfer:
```bash
sha256sum "/backups/<db>.backup"
```

- **Automated test restore** (recommended in CI or a sandbox):
```bash
createdb -U <user> restore_test
pg_restore -U <user> -d restore_test "/backups/<db>.backup"
# run smoke tests, then dropdb restore_test
```

---

## 🧯 Troubleshooting

- `pg_dump: error: query failed`: check permissions for objects or use a higher‑privileged role.  
- `pg_restore: could not execute CREATE EXTENSION`: ensure the same extensions exist on target.  
- Collation/version mismatch: restoring across major versions may require `pg_upgrade` or logical dump/restore with compatible locales.  
- Large objects missing: ensure `-b` was used during dump and `lo` extension exists on target if needed.

---

## 🛡️ Best Practices Checklist

- At least **1 full backup per day** + WAL archiving for PITR on critical systems.  
- Keep **off‑site copies** (separate account/region).  
- **Encrypt** backups (at rest + in transit).  
- Rotate & **test restores** regularly.  
- Version your backup scripts; monitor success/failures with alerts.  
- Document RPO/RTO and validate they’re met.

---

### Appendix: Sample Env Setup

```bash
export PGHOST=localhost
export PGPORT=5432
export PGUSER=app_backup
export PGPASSWORD='use-.pgpass-instead'
```

Happy backing up! 🧰
