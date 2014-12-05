
// These two lines are required to initialize Express in Cloud Code.
var express = require('express');
var app = express();
var versionTracker = require('cloud/versionTracker.js');

// Global app configuration section
app.set('views', 'cloud/views');  // Specify the folder to find templates
app.set('view engine', 'ejs');    // Set the template engine
app.use(express.bodyParser());    // Middleware for reading request body

app.post('/builds', function(req, res) {
  console.log(JSON.stringify(req.body));
  return res.send("");
});

app.get('/track/:channel', function(req, res) {
  var channel = req.params.channel;
  var bundleIdentifier = req.query['bundle_identifier'];
  versionTracker.versionPackageForTrackerRequest(bundleIdentifier, channel).then(function(versionPackage) {
    return res.send(versionPackage);
  }, function(error) {
    return res.status(500).send(error);
  });
});

app.listen();
