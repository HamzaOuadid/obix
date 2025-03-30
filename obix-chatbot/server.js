const express = require('express');
const path = require('path');
const app = express();

// Serve static files from the dist directory
app.use(express.static(__dirname + '/dist/debt-chatbot'));

// Send all requests to index.html so Angular can handle routing
app.get('/*', function(req, res) {
  res.sendFile(path.join(__dirname + '/dist/debt-chatbot/index.html'));
});

// Start the app by listening on the default Heroku port
const port = process.env.PORT || 4200;
app.listen(port, () => {
  console.log(`Server is running on port ${port}`);
}); 