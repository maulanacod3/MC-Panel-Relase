<p align="center">
  <img src="assets/logo_white.png" alt="MC-Panel Logo" width="100" />
</p>

<h1 align="center">MC-Panel (MCode Server & App Control Panel)</h1>

<p align="center">
  <strong>Ultra-lightweight, high-performance Linux Server & CBT App Control Daemon written in Go and Vue 3.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Go-1.22%2B-00ADD8?style=flat&logo=go" alt="Go Version" />
  <img src="https://img.shields.io/badge/Vue-3.4%2B-4FC08D?style=flat&logo=vue.js" alt="Vue 3" />
  <img src="https://img.shields.io/badge/RAM_Usage-%3C_20MB-emerald?style=flat" alt="Ultra Low RAM" />
  <img src="https://img.shields.io/badge/Architecture-Single_Binary-indigo?style=flat" alt="Single Binary" />
  <img src="https://img.shields.io/badge/License-MIT-blue?style=flat" alt="License" />
</p>

---

## 🚀 Overview

**MC-Panel** adalah daemon server control panel yang dirancang khusus untuk mengelola aplikasi **MC-ExamGO (Go CBT Core)** dan **Laravel Web Applications** dengan konsumsi memori yang luar biasa hemat (**< 20 MB RAM**), dibandingkan panel server konvensional yang memakan 500MB+ RAM.

Frontend Vue 3 SPA di-embed langsung ke dalam single binary executable Go, sehingga tidak memerlukan instalasi Node.js atau runtime tambahan saat di-deploy di VPS.

---

## ✨ Key Features

- ⚡ **Ultra Low Memory Footprint:** Konsumsi RAM di bawah 20 MB, cocok untuk VPS spek hemat (1 vCPU, 1 GB RAM).
- 📦 **Single-Binary Zero-Dependency:** Frontend Vue 3 ter-embed penuh ke dalam satu file binary executable (`//go:embed`).
- 🎯 **Tailored for CBT & School Workloads:**
  - **Go Apps (MC-ExamGO):** Daemon systemd terisolasi, port allocator otomatis (anti-collision), reverse proxy Nginx.
  - **Laravel Apps:** Multi-version PHP-FPM sockets, FastCGI Nginx passing, helper artisan & composer.
- 🗄️ **Database Provisioner:** Otomasi pembuatan user dan database terisolasi untuk **PostgreSQL** (CBT Core) dan **MySQL/MariaDB** (Laravel).
- 🔒 **One-Click SSL & Firewall:** Auto-issue dan auto-renew Let's Encrypt SSL via Certbot serta manajemen aturan port UFW.
- 🔄 **1-Click Auto-Updater:** Pembaruan versi in-place langsung dari GitHub Releases tanpa downtime.
- 📊 **Live Telemetry:** Metrik CPU, RAM, Disk, Uptime, dan supervise daemons secara real-time dengan Smart Page Visibility API.

---

## 🛠️ Tech Stack

| Layer | Technologies |
| :--- | :--- |
| **Backend Engine** | Go 1.22+, Gin Web Framework, GORM, Pure-Go SQLite, gopsutil |
| **Frontend UI** | Vue 3 (Composition API), Vite, Tailwind CSS, Lucide Icons, Pinia |
| **Target OS** | Ubuntu 20.04 / 22.04 / 24.04 LTS, Debian 11 / 12 |

---

## 🚀 Quick Start (One-Line Linux Installation)

Jalankan perintah berikut di terminal SSH VPS Ubuntu/Debian Anda sebagai `root`:

```bash
curl -sSL https://raw.githubusercontent.com/maulanacod3/MC-Panel-Relase/main/install.sh | bash
```

Setelah instalasi selesai, buka browser di:
👉 **`http://IP_VPS_ANDA:9090`**
- **Default User:** `admin`
- **Default Password:** `admin123`

---

## 💻 Local Development

### 1. Jalankan Backend (Go)
```bash
cd backend
go run cmd/server/main.go
```

### 2. Jalankan Frontend (Vite)
```bash
cd frontend
npm install
npm run dev
```

### 3. Build Single Binary (Multi-Platform)
```powershell
# Windows (PowerShell)
.\scripts\build.ps1
```
```bash
# Linux (Bash)
./scripts/build.sh
```

---

## 📄 License
Project ini dilisensikan di bawah lisensi MIT.
