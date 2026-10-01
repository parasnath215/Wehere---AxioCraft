# 🚀 Hostinger VPS Deployment Plan for Wehere

Since you already have a CRM running on this VPS, the primary directive is **Zero Disruption**. We will achieve this by isolating Wehere inside Docker and using your existing web server (Nginx/Apache) as a reverse proxy.

## 1. Domain & DNS Preparation
You will need two subdomains pointing to your Hostinger VPS IP address:
- `api.yourdomain.com` (For the Node.js backend)
- `admin.yourdomain.com` (For the Next.js admin panel)

## 2. Preventing Port Conflicts (Already Optimized)
I have preemptively modified your `docker-compose.yml` to be shared-VPS safe:
1. **Database Isolation**: The PostgreSQL database port (`5432`) is no longer exposed to the host machine. It communicates with the backend exclusively on the internal Docker network. This guarantees it will **not** conflict with your CRM's database.
2. **Localhost Binding**: The Backend (`4000`) and Admin Panel (`3000`) ports are now bound strictly to `127.0.0.1`. They cannot be accessed directly from the open internet, preventing port conflicts and shielding them until Nginx serves them securely.
3. **High Availability**: Added `restart: unless-stopped` so Wehere components automatically boot if the VPS restarts.

## 3. Deployment Execution Steps

### Step A: Transfer Files to the VPS
Upload the Wehere repository to a dedicated folder on your VPS, completely separate from your CRM (e.g., `/var/www/wehere`). You can use `scp`, `rsync`, or Git to clone it.

### Step B: Configure Production Secrets
On the VPS, create a `.env` file in the `backend` and `admin-panel` directories (or define them securely in `docker-compose.yml`). 
**Crucially**, update the following in `docker-compose.yml` before starting:
- `JWT_SECRET`: Make this a long, secure random string.
- `FRONTEND_URL`: The URL of your future Flutter Web app (if any).
- `ADMIN_URL`: Set to `https://admin.yourdomain.com`.
- `NEXT_PUBLIC_API_URL`: Set to `https://api.yourdomain.com` (This is how the admin panel frontend will talk to the backend).

### Step C: Spin Up the Docker Cluster
Run the following command in the root `Wehere` folder on your VPS:
```bash
docker-compose up --build -d
```
Docker will build the images, start the isolated database, push the Prisma schema automatically, and start both servers in the background.

## 4. Nginx Reverse Proxy & SSL (Zero Disruption Setup)
Instead of modifying your CRM's web configuration, you will create two *new, separate* Nginx Server Blocks to route traffic to the Docker containers.

### Create `api.yourdomain.com` block (`/etc/nginx/sites-available/wehere-api`):
```nginx
server {
    listen 80;
    server_name api.yourdomain.com;

    location / {
        proxy_pass http://127.0.0.1:4000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

### Create `admin.yourdomain.com` block (`/etc/nginx/sites-available/wehere-admin`):
```nginx
server {
    listen 80;
    server_name admin.yourdomain.com;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

### Activate and Secure:
1. Link them: `sudo ln -s /etc/nginx/sites-available/wehere-* /etc/nginx/sites-enabled/`
2. Test Nginx to ensure CRM is unharmed: `sudo nginx -t`
3. Reload Nginx: `sudo systemctl reload nginx`
4. Secure with Let's Encrypt: `sudo certbot --nginx -d api.yourdomain.com -d admin.yourdomain.com`

## 5. Connecting the Flutter App
Once deployed, compile your Flutter app targeting the new production API URL:
```bash
flutter build apk --dart-define=API_URL=https://api.yourdomain.com/api
```
