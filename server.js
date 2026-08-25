const http = require('http');
const fs = require('fs');
const path = require('path');
const url = require('url');

const PORT = process.env.PORT || 3000;
const HOST = '0.0.0.0';

const MIME_TYPES = {
  '.html': 'text/html',
  '.css': 'text/css',
  '.js': 'application/javascript',
  '.json': 'application/json',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.gif': 'image/gif',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon'
};

const server = http.createServer((req, res) => {
  // 解析请求URL
  const parsedUrl = url.parse(req.url, true);
  let pathname = parsedUrl.pathname;

  // 移除前导斜杠
  if (pathname.startsWith('/')) {
    pathname = pathname.slice(1);
  }

  // 默认文件
  if (pathname === '' || pathname === '/') {
    pathname = 'index.html';
  }

  // 构建文件路径
  const filePath = path.join(__dirname, pathname);

  // 安全检查：防止路径遍历
  const realPath = fs.realpathSync(__dirname);
  const realFilePath = fs.realpathSync(filePath);
  
  if (!realFilePath.startsWith(realPath)) {
    res.writeHead(403, { 'Content-Type': 'text/plain' });
    res.end('403 Forbidden');
    return;
  }

  // 检查文件是否存在
  fs.stat(filePath, (err, stats) => {
    if (err) {
      // 文件不存在，返回404
      res.writeHead(404, { 'Content-Type': 'text/html; charset=utf-8' });
      res.end(`
        <!DOCTYPE html>
        <html lang="zh-CN">
        <head>
          <meta charset="UTF-8">
          <title>404 - 页面不存在</title>
        </head>
        <body style="font-family: Arial; text-align: center; padding: 50px;">
          <h1>404 - 页面不存在</h1>
          <p>请求的文件: ${pathname}</p>
          <a href="/">返回首页</a>
        </body>
        </html>
      `);
      return;
    }

    if (stats.isDirectory()) {
      // 如果是目录，尝试加载index.html
      const indexPath = path.join(filePath, 'index.html');
      fs.readFile(indexPath, (err, data) => {
        if (err) {
          res.writeHead(404, { 'Content-Type': 'text/plain' });
          res.end('404 Not Found');
        } else {
          res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
          res.end(data);
        }
      });
    } else if (stats.isFile()) {
      // 获取文件扩展名
      const ext = path.extname(filePath).toLowerCase();
      const mimeType = MIME_TYPES[ext] || 'application/octet-stream';

      fs.readFile(filePath, (err, data) => {
        if (err) {
          res.writeHead(500, { 'Content-Type': 'text/plain' });
          res.end('500 Internal Server Error');
        } else {
          res.writeHead(200, {
            'Content-Type': `${mimeType}; charset=utf-8`,
            'Cache-Control': 'no-cache'
          });
          res.end(data);
        }
      });
    } else {
      res.writeHead(403, { 'Content-Type': 'text/plain' });
      res.end('403 Forbidden');
    }
  });
});

server.listen(PORT, HOST, () => {
  console.log(`
╔════════════════════════════════════════════════════════════╗
║         🚀 Admin System Server 启动成功!                  ║
╚══════════════════════════════════════════════════════════╝

📍 服务器地址: http://localhost:${PORT}
📍 外网访问: http://<your-server-ip>:${PORT}

🎬 主页面:    http://localhost:${PORT}/index.html
🔌 Hosts管理: http://localhost:${PORT}/hosts.html

🔑 管理员账户: feiji / 888888

📊 CI/CD工作流程:
  - Google Cloud: .github/workflows/google.yml
  - Terraform:    .github/workflows/terraform.yml

✅ 服务器运行中... 按 Ctrl+C 停止
  `);
});

server.on('error', (err) => {
  if (err.code === 'EADDRINUSE') {
    console.error(`❌ 端口 ${PORT} 已被占用，请尝试使用其他端口`);
    process.exit(1);
  } else {
    console.error('❌ 服务器错误:', err);
    process.exit(1);
  }
});

// 优雅关闭
process.on('SIGTERM', () => {
  console.log('\n📴 服务器正在关闭...');
  server.close(() => {
    console.log('✅ 服务器已关闭');
    process.exit(0);
  });
});
