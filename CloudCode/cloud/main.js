
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

Parse.Cloud.afterSave("Vybe", function(request, response) {
  var userGeoPoint = request.object.get("location");
  console.log("userGeoPoint: " + userGeoPoint);

  var query = new Parse.Query("Vybe");
  console.log("query: " + query);

  query.near("location", userGeoPoint);
  query.limit(10);
  query.find({
    success: function(vybesObjects) {
      console.log("Returning responses: " + vybesObjects);
      response.success(vybesObjects);
    },
    error: function(error) {
      console.error("Got an error " + error.code + " : " + error.message);
    }
  });
});
