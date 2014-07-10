
var utils = require('cloud/utils');
require('cloud/yo');
require('cloud/compatibility');


// recentVybesExcludingYouInReverse
var algorithm1 = utils.curry(
  get_vybes, {
    recent: true,
    hide_user: true,
    reversed: true,
  });

// recentNearbyVybesInReverse
var algorithm2 = utils.curry(
  get_vybes, {
    recent: true,
    nearby: true,
    reversed: true,
  });

// recentNearbyVybesExcludingYou
var algorithm3 = utils.curry(
  get_vybes, {
    recent: true,
    nearby: true,
    hide_user: true,
  });


// Default algorithm used in the app
Parse.Cloud.define("default_algorithm", algorithm1);

// Algorithms that can be chosen from the debug menu
Parse.Cloud.define("algorithm1", algorithm1);
Parse.Cloud.define("algorithm2", algorithm2);
Parse.Cloud.define("algorithm3", algorithm3);


// Generic get_vybes functions that accepts options
function get_vybes(options, request, response) {
  var recent = options.recent || false;
  var nearby = options.nearby || false;
  var hide_user = options.hide_user || false;
  var reversed = options.reversed || false;
  var limit = options.limit || 10;

  var userGeoPoint = request.params.location;
  var currentUser = Parse.User.current();

  var query = new Parse.Query("Vybe");

  if (recent) query.addDescending("timestamp");
  if (nearby) query.near("location", userGeoPoint);
  if (hide_user) query.notEqualTo("user", currentUser);
  if (limit) query.limit(limit);

  query.find({
    success: function(vybesObjects) {
      var result;
      if (reversed) {
        result = vybesObjects;
      } else {
        // Sort result in chronological order
        result = vybesObjects.reverse();
      }
      response.success(result);
    },
    error: function() {
      response.error("cannot find vybes around you");
    }
  });
}
