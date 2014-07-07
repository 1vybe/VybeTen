
var default_limit = 5;

// Renamed to nearbyVybe. Delete when possible.
Parse.Cloud.define("closestVybes", function(request, response) {
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
});

// Get nearby vybes using the Parse.Query.near method
Parse.Cloud.define("nearbyVybes", function(request, response) {
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
});

// Get most recent vybes
Parse.Cloud.define("recentVybes", function(request, response) {
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
});

// Get nearby vybes using the Parse.Query.near method then sort by most recent
Parse.Cloud.define("recentNearbyVybes", function(request, response) {
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
});
