// Do not delete
Parse.Cloud.define("closestVybes", function(request, response) {
  var userGeoPoint = request.params.location;
  var query = new Parse.Query("Vybe");
  query.near("location", userGeoPoint);
  query.limit(10);
  query.find({
    success: function(vybesObjects) {
      response.success(vybesObjects);
    },
    error: function() {
      response.error("cannot find vybes around you");
    }
  });
});

Parse.Cloud.define("nearbyVybes", function(request, response) {
  var userGeoPoint = request.params.location;
  var query = new Parse.Query("Vybe");
  query.near("location", userGeoPoint);
  query.limit(10);
  query.find({
    success: function(vybesObjects) {
      response.success(vybesObjects);
    },
    error: function() {
      response.error("cannot find vybes around you");
    }
  });
});

// Parse.Cloud.afterSave("Vybe", function(request, response) {
//   var userGeoPoint = request.object.get("location");
//   console.log("userGeoPoint: " + userGeoPoint);

//   var query = new Parse.Query("Vybe");
//   console.log("query: " + query);

//   query.near("location", userGeoPoint);
//   query.limit(10);
//   query.find({
//     success: function(vybesObjects) {
//       console.log("Returning responses: " + vybesObjects);
//       response.success(vybesObjects);
//     },
//     error: function(error) {
//       console.error("Got an error " + error.code + " : " + error.message);
//     }
//   });
// });

var default_limit = 5;

Parse.Cloud.define("recentVybes", function(request, response) {
  console.log("request.params:" + JSON.stringify(request.params));
  var userGeoPoint = request.params.location;
  var query = new Parse.Query("Vybe");
  query.descending("timestamp");
  if (request.params.limit) {
    console.log("limit given: " + request.params.limit);
  } else {
    console.log("using default limit: " + default_limit);
    query.limit(default_limit);
  }
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

Parse.Cloud.define("recentNearbyVybes", function(request, response) {
  console.log("request.params:" + JSON.stringify(request.params));
  var userGeoPoint = request.params.location;
  var query = new Parse.Query("Vybe");
  query.near("location", userGeoPoint);
  query.addDescending("timestamp");
  if (request.params.limit) {
    console.log("limit given: " + request.params.limit);
  } else {
    console.log("using default limit: " + default_limit);
    query.limit(default_limit);
  }
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
