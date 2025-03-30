const express = require('express');
const path = require('path');
const app = express();

console.log('Starting server...');
console.log('Current directory:', __dirname);

// Check if dist directory exists
const fs = require('fs');
const distPath = path.join(__dirname, 'dist/debt-chatbot');
if (!fs.existsSync(distPath)) {
  console.log('Creating dist/debt-chatbot directory');
  fs.mkdirSync(distPath, { recursive: true });
}

const browserPath = path.join(distPath, 'browser');
if (!fs.existsSync(browserPath)) {
  console.log('Creating dist/debt-chatbot/browser directory');
  fs.mkdirSync(browserPath, { recursive: true });
}

const indexPath = path.join(browserPath, 'index.html');
if (!fs.existsSync(indexPath)) {
  console.log('Creating minimal index.html');
  const minimalHtml = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>OBIX Chatbot</title>
  <base href="/">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link rel="icon" type="image/x-icon" href="favicon.ico">
  <style>
    body {
      font-family: Arial, sans-serif;
      margin: 0;
      padding: 20px;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      background-color: #f5f5f5;
    }
    .container {
      max-width: 800px;
      text-align: center;
      background: white;
      padding: 30px;
      border-radius: 8px;
      box-shadow: 0 2px 10px rgba(0,0,0,0.1);
    }
    h1 {
      color: #333;
    }
    p {
      color: #666;
      line-height: 1.6;
    }
    .btn {
      background-color: #4CAF50;
      color: white;
      padding: 10px 20px;
      text-decoration: none;
      border-radius: 4px;
      display: inline-block;
      margin-top: 20px;
    }
  </style>
</head>
<body>
  <div class="container">
    <h1>Welcome to OBIX Chatbot</h1>
    <p>The application is loading or being built. If this message persists, please contact the administrator.</p>
    <a href="/api/admin/" class="btn">Admin Dashboard</a>
  </div>
</body>
</html>`;
  fs.writeFileSync(indexPath, minimalHtml);
}

// Serve static files from the Angular browser directory
app.use(express.static(browserPath));

// Send all requests to index.html
app.get('/*', function(req, res) {
  console.log('Serving request for:', req.path);
  res.sendFile(path.join(browserPath, 'index.html'));
});

// Start the app by listening on the default port
const port = process.env.PORT || 10000;
app.listen(port, () => {
  console.log(`Server is running on port ${port}`);
}); 