const { Client } = require('ssh2');

const conn = new Client();
conn.on('ready', () => {
  console.log('Client :: ready');
  conn.exec('rm -rf /tmp/wehere-repo && git clone https://github.com/parasnath215/Wehere---AxioCraft.git /tmp/wehere-repo && cd /tmp/wehere-repo && git checkout fix/email-verification && rm -rf /var/www/wehere/backend/node_modules /var/www/wehere/admin-panel/node_modules && cp -r backend/* /var/www/wehere/backend/ && cp docker-compose.yml /var/www/wehere/ && cd /var/www/wehere && docker compose build backend && docker compose up -d', (err, stream) => {
    if (err) throw err;
    stream.on('close', (code, signal) => {
      conn.end();
    }).on('data', (data) => {
      console.log('STDOUT: ' + data);
    }).stderr.on('data', (data) => {
      console.log('STDERR: ' + data);
    });
  });
}).connect({
  host: '200.97.165.22',
  port: 22,
  username: 'root',
  password: 'Axiocraft@1221'
});
