const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 8080;

const MIME_TYPES = {
  '.html': 'text/html',
  '.css': 'text/css',
  '.js': 'text/javascript',
  '.json': 'application/json',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
};

const server = http.createServer((req, res) => {
  let reqUrl = req.url.split('?')[0];
  
  if (reqUrl === '/' || reqUrl === '/website' || reqUrl === '/website/') {
    reqUrl = '/website/index.html';
  } else if (reqUrl === '/preview' || reqUrl === '/preview/') {
    reqUrl = '/preview/index.html';
  }

  let filePath = path.join(__dirname, reqUrl);

  // Check if file exists directly at root, or under /website/
  fs.stat(filePath, (err, stats) => {
    if (err || !stats.isFile()) {
      // Try resolving inside website/ directory
      const websiteFilePath = path.join(__dirname, 'website', reqUrl);
      fs.stat(websiteFilePath, (wErr, wStats) => {
        if (!wErr && wStats.isFile()) {
          sendFile(res, websiteFilePath);
        } else {
          // Try resolving inside preview/ directory
          const previewFilePath = path.join(__dirname, 'preview', reqUrl);
          fs.stat(previewFilePath, (pErr, pStats) => {
            if (!pErr && pStats.isFile()) {
              sendFile(res, previewFilePath);
            } else {
              res.writeHead(404, { 'Content-Type': 'text/plain' });
              res.end('404 Not Found');
            }
          });
        }
      });
      return;
    }

    sendFile(res, filePath);
  });
});

function sendFile(res, filePath) {
  const ext = path.extname(filePath).toLowerCase();
  const contentType = MIME_TYPES[ext] || 'application/octet-stream';

  res.writeHead(200, {
    'Content-Type': contentType,
    'Access-Control-Allow-Origin': '*',
  });

  const stream = fs.createReadStream(filePath);
  stream.pipe(res);
}

server.listen(PORT, () => {
  console.log(`Wehere Web Showcase running at http://localhost:${PORT}`);
});
