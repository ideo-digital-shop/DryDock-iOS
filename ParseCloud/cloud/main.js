
require('cloud/app.js');

var VDDModelApp = Parse.Object.extend("VDDModelApp");

Parse.Cloud.define("buildServerUpdate", function(request, response) {
  console.log(JSON.stringify(request.params));
  var bundleIdentifier = request.params['bundle_identifier'];
  var versionChannel = request.params['version_channel'];
  var installUrl = request.params['install_url'];
  var versionNumber = request.params['version_number'];
  var buildNumber = request.params['build_number'];
  var foundModelApp;
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
    foundModelApp = object;
    var pushData = {
      data: {
        alert: "New version available for " + foundModelApp.get("name") + "!",
        sound: "default",
        category: "update",
        "install_url": installUrl
      },
      channels: ["global"]
    };
    return Parse.Push.send(pushData);
  }).then(function() {
    console.log("sent push");
    return response.success(foundModelApp);
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