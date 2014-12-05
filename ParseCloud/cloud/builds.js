
var VDDModelApp = Parse.Object.extend("VDDModelApp");

var updateAppFromBuildPackage = function(buildPackage) {
  var promise = new Parse.Promise();

  var jobName = buildPackage.job.name;
  var modelAppQuery = new Parse.Query(VDDModelApp);
  modelAppQuery.equalTo("buildJobName", jobName);
  modelAppQuery.first().then(function(modelApp) {
    if (!modelApp) {
      promise.reject("No model app found that matches job name: " + jobName);
    } else {
      modelApp.set("install_url", buildPackage.installURL); // NEED TO FIGURE OUT THIS KEY
      modelApp.set("version_number", buildPackage.versionNumber); // NEED TO FIGURE OUT THIS KEY
      modelApp.set("build_number", buildPackage.build["build_number"]); // NEED TO FIGURE OUT THIS KEY
      return modelApp.save();
    }
  });

  return promise;
};

module.exports.updateAppFromBuildPackage = updateAppFromBuildPackage;
