$VPS_IP = "200.97.165.22"
$USER = "root"

Write-Host "Zipping backend..." -ForegroundColor Cyan
Compress-Archive -Path .\backend\* -DestinationPath backend_update.zip -Force

Write-Host "Uploading backend to VPS..." -ForegroundColor Cyan
Write-Host "When prompted, enter the password: Axiocraft@1221" -ForegroundColor Yellow
scp backend_update.zip ${USER}@${VPS_IP}:/root/Wehere/

Write-Host "Extracting and restarting backend on VPS..." -ForegroundColor Cyan
ssh ${USER}@${VPS_IP} "cd /root/Wehere && unzip -o backend_update.zip -d backend && cd backend && npm install && npx prisma db push && docker-compose build && docker-compose up -d"

Write-Host "Cleaning up..." -ForegroundColor Cyan
Remove-Item backend_update.zip

Write-Host "Deployment completed!" -ForegroundColor Green
