
// These two lines are required to initialize Express in Cloud Code.
var express = require('express');
var app = express();
var versionTracker = require('cloud/versionTracker.js');

var VDDModelApp = Parse.Object.extend("VDDModelApp");

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

app.get('/appdownload/:objectId', function(req, res) {
  var modelAppQuery = new Parse.Query(VDDModelApp);
  modelAppQuery.get(req.params.objectId).then(function(modelApp) {
    if (!modelApp) {
      
    } else {
      var renderPackage = {};
      renderPackage['name'] = modelApp.get('name');
      renderPackage['version_number'] = modelApp.get('version_number');
      renderPackage['install_url'] = modelApp.get('install_url');
      renderPackage['icon_url'] = modelApp.get('image').url();
      renderPackage['description'] = modelApp.get('description');
      return res.render('appdownload', renderPackage);
    }
  });
});

app.listen();
