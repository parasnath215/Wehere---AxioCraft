const { Client } = require('ssh2');
const fs = require('fs');
const path = require('path');

const conn = new Client();
const config = {
  host: '200.97.165.22',
  port: 22,
  username: 'root',
  password: 'Axiocraft@1221',
  readyTimeout: 30000
};

conn.on('ready', () => {
  console.log('SSH Client :: ready');

  // Step 1: Upload the file
  conn.sftp((err, sftp) => {
    if (err) {
      console.error('SFTP Error:', err);
      conn.end();
      return;
    }
    
    console.log('SFTP :: ready - uploading wehere-deploy.tar');
    const localPath = path.join(__dirname, 'wehere-deploy.tar');
    const remotePath = '/root/wehere-deploy.tar';

    sftp.fastPut(localPath, remotePath, (err) => {
      if (err) {
        console.error('Upload Error:', err);
        conn.end();
        return;
      }
      console.log('Upload :: success');

      // Step 2: Execute deployment commands
      const commands = `
        mkdir -p /var/www/wehere
        mv /root/wehere-deploy.tar /var/www/wehere/
        cd /var/www/wehere
        tar -xf wehere-deploy.tar
        rm wehere-deploy.tar
        docker compose down || true
        docker compose up --build -d
        sleep 5
        docker compose exec -T backend npx prisma db push
      `;

      console.log('Executing deployment commands...');
      conn.exec(commands, (err, stream) => {
        if (err) {
          console.error('Exec Error:', err);
          conn.end();
          return;
        }

        stream.on('close', (code, signal) => {
          console.log('Deployment stream :: close :: code: ' + code + ', signal: ' + signal);
          conn.end();
        }).on('data', (data) => {
          console.log('STDOUT: ' + data);
        }).stderr.on('data', (data) => {
          console.log('STDERR: ' + data);
        });
      });
    });
  });
}).on('error', (err) => {
  console.error('SSH Error:', err);
}).connect(config);
