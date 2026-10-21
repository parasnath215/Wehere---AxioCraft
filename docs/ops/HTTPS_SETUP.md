# HTTPS & Reverse Proxy Setup (Nginx + Let's Encrypt)

This runbook guides deploying the Wehere backend behind an Nginx reverse proxy secured by Let's Encrypt TLS certificates.

---

## 1. Prerequisites

- A registered domain name pointing its `A` record (e.g., `api.YOUR_DOMAIN`) to your VPS server IP.
- Nginx installed on host or as a Docker container.
- Certbot installed (`apt install certbot python3-certbot-nginx` on Debian/Ubuntu).
- Wehere backend running on internal port `4000`.

---

## 2. Obtain SSL/TLS Certificate with Certbot

Run Certbot to request a Let's Encrypt certificate:

```bash
sudo certbot certonly --nginx -d api.YOUR_DOMAIN
```

Certificates will be stored at:
- `/etc/letsencrypt/live/api.YOUR_DOMAIN/fullchain.pem`
- `/etc/letsencrypt/live/api.YOUR_DOMAIN/privkey.pem`

Auto-renewal is verified with:
```bash
sudo certbot renew --dry-run
```

---

## 3. Nginx Configuration

Create or update `/etc/nginx/sites-available/wehere-api.conf`:

```nginx
# HTTP - Redirect all traffic to HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name api.YOUR_DOMAIN;

    return 301 https://$host$request_uri;
}

# HTTPS Server
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name api.YOUR_DOMAIN;

    ssl_certificate /etc/letsencrypt/live/api.YOUR_DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.YOUR_DOMAIN/privkey.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 1d;

    # Maximum upload size for photo uploads
    client_max_body_size 10M;

    # Reverse proxy to backend Express / Socket.IO
    location / {
        proxy_pass http://127.0.0.1:4000;
        proxy_http_version 1.1;

        # WebSocket support
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";

        # Forwarded headers
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Timeouts for persistent WebSocket connections
        proxy_read_timeout 86400s;
        proxy_send_timeout 86400s;
    }
}
```

Enable the configuration and reload Nginx:
```bash
sudo ln -sf /etc/nginx/sites-available/wehere-api.conf /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

---

## 4. Backend Environment Configuration

Ensure your `backend/.env` has:
```env
TRUST_PROXY_HOPS=1
PORT=4000
NODE_ENV=production
```

When `TRUST_PROXY_HOPS=1`, Express properly resolves client IP addresses through the `X-Forwarded-For` header for IP-based rate limiting.

---

## 5. Flutter Client Release Build Command

In release builds, cleartext traffic is disabled on both Android and iOS. The app will refuse to start if compiled with an unencrypted `http://` URL.

Build the Android release bundle using:
```bash
flutter build appbundle --release --dart-define=API_URL=https://api.YOUR_DOMAIN/api
```

For iOS:
```bash
flutter build ipa --release --dart-define=API_URL=https://api.YOUR_DOMAIN/api
```

> **IMPORTANT**: Release builds require an `https://` endpoint and will not run until the server has a valid SSL/TLS certificate configured.
