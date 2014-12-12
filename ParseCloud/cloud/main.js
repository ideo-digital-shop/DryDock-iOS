
require('cloud/app.js');

var VDDModelApp = Parse.Object.extend("VDDModelApp");

// Use Parse.Cloud.define to define as many cloud functions as you want.
// For example:
Parse.Cloud.define("hello", function(request, response) {
  response.success("Hello world!");
});

Parse.Cloud.define("buildServerUpdate", function(request, response) {
  console.log(JSON.stringify(request.params));
  var bundleIdentifier = request.params['bundle_identifier'];
  var versionChannel = request.params['version_channel'];
  var installUrl = request.params['install_url'];
  var versionNumber = request.params['version_number'];
  var buildNumber = request.params['build_number'];
  getModelApp(bundleIdentifier, versionChannel).then(function(modelApp) {
    if (!modelApp) {
      return Parse.Promise.error("No model app found that matches bundleIdentifier: " + bundleIdentifier + " and channel: " + versionChannel);
    } else {
      modelApp.set('install_url', installUrl);
      modelApp.set('version_number', versionNumber);
      modelApp.set('build_number', buildNumber);
      return modelApp.save();
    }
  }).then(function(object) {
    return response.success(object);
  }, function(err) {
    return response.error(JSON.stringify(err));
  });
});

var getModelApp = function(bundleIdentifier, versionChannel) {
  var modelAppQuery = new Parse.Query(VDDModelApp);
  modelAppQuery.equalTo("bundle_identifier", bundleIdentifier);
  modelAppQuery.equalTo("version_channel", versionChannel);
  return modelAppQuery.first();
};