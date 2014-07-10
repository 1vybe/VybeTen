
// Renamed to nearbyVybe. Delete when possible.
Parse.Cloud.define("closestVybes", nearbyVybes);
Parse.Cloud.define("nearbyVybes", nearbyVybes);
Parse.Cloud.define("recentVybes", recentVybes);
Parse.Cloud.define("recentNearbyVybes", recentNearbyVybes);

// Algorithms that can be chosen from the debug menu
Parse.Cloud.define("algorithm1", recentVybes);
Parse.Cloud.define("algorithm2", recentNearbyVybes);
Parse.Cloud.define("algorithm3", recentNearbyVybesExcludingYou);

Parse.Cloud.define("default_algorithm", recentNearbyVybesExcludingYou);
var utils = require('cloud/utils');
require('cloud/yo');


var default_limit = 5;

// Get nearby vybes using the Parse.Query.near method
function nearbyVybes(request, response) {
  var userGeoPoint = request.params.location;
  var query = new Parse.Query("Vybe");
  query.near("location", userGeoPoint);
  query.limit(default_limit);
  query.find({
    success: function(vybesObjects) {
      response.success(vybesObjects);
    },
    error: function() {
      response.error("cannot find vybes around you");
    }
  });
}

// Get most recent vybes
function recentVybes(request, response) {
  var userGeoPoint = request.params.location;
  var query = new Parse.Query("Vybe");
  query.descending("timestamp");
  query.limit(default_limit);
  query.find({
    success: function(vybesObjects) {
      // Sort result in chronological order
      response.success(vybesObjects.reverse());
    },
    error: function() {
      response.error("cannot find vybes around you");
    }
  });
}

// Get nearby vybes using the Parse.Query.near method then sort by most recent
function recentNearbyVybes(request, response) {
  var userGeoPoint = request.params.location;
  var query = new Parse.Query("Vybe");
  query.near("location", userGeoPoint);
  query.addDescending("timestamp");
  query.limit(default_limit);
  query.find({
    success: function(vybesObjects) {
      // Sort result in chronological order
      response.success(vybesObjects.reverse());
    },
    error: function() {
      response.error("cannot find vybes around you");
    }
  });
}

// Get nearby vybes using the Parse.Query.near method then sort by most recent
// Exclugin you
function recentNearbyVybesExcludingYou(request, response) {
  var userGeoPoint = request.params.location;
  var query = new Parse.Query("Vybe");
  var currentUser = Parse.User.current();
  query.near("location", userGeoPoint);
  query.limit(default_limit);
  query.addDescending("timestamp");
  query.notEqualTo("user", currentUser);
  query.find({
    success: function(vybesObjects) {
      // Sort result in chronological order
      response.success(vybesObjects.reverse());
    },
    error: function() {
      response.error("cannot find vybes around you");
    }
  });
}
