
var VDDModelApp = Parse.Object.extend("VDDModelApp");

var versionPackageForTrackerRequest = function(bundleIdentifier, channel) {
  var promise = new Parse.Promise();

  var modelAppQuery = new Parse.Query(VDDModelApp);
  modelAppQuery.equalTo("bundle_identifier", bundleIdentifier);
  modelAppQuery.equalTo("version_channel", channel);
  modelAppQuery.first().then(function(modelApp) {
    if (!modelApp) {
      promise.reject("No model app found that matches bundleIdentifier: " + bundleIdentifier + " and channel: " + channel);
    } else {
      var returnPackage = {};
      var versionPackage = {};
      versionPackage["number"] = modelApp.get("version_number");
      versionPackage["mandatory"] = modelApp.get("mandatory_update") || false;
      versionPackage["install_url"] = modelApp.get("install_url");
      returnPackage["version"] = versionPackage;
      promise.resolve(returnPackage);
    }
  });

  return promise;
};

module.exports.versionPackageForTrackerRequest = versionPackageForTrackerRequest;
