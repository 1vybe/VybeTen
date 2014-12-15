require('cloud/tribe');

var _ = require('underscore');
var Vybe = Parse.Object.extend('Vybe');


// Validate Vybes have a valid owner in the "user" pointer.
Parse.Cloud.beforeSave('Vybe', function (request, response) {
  var objectUser = request.object.get('user');

  if(!objectUser) {
    response.error('A Vybe should have a valid user.');
  }
  else {
    response.success();
  }
});


Parse.Cloud.afterSave('Vybe', function (request) {
  // Continue only for new vybes
  if (request.object.existed()) {
    return;
  }

  if (request.object.get('isPublic')) {
    // Set User's mostRecentVybe to this vybe
    var currentUser = request.user;
    currentUser.set('mostRecentVybe', request.object);
    currentUser.save().then(
      function(result) {
        console.log('user most recent vybe updated');
      },
      function(error) {
        console.log('user most recent vybe NOT updated');
      }
    );
  }

  // Insert this new vybe to each user's freshFeed
  Parse.Cloud.useMasterKey();
  var query = new Parse.Query(Parse.User);
  query.notEqualTo('username', request.user.get('username'));
  query.each(function(user) {
    console.log('feeding to ' + user.get('username'));

    var feed = user.relation('feed');
    feed.add(request.object);
    user.save();
    console.log('successfully fed to ' + user.get('username'));
  });

});


Parse.Cloud.afterDelete('Vybe', function (request) {
  // Set up to modify user data
  Parse.Cloud.useMasterKey();

  var deletedVybe = request.object;

  // Query for all users
  var query = new Parse.Query(Parse.User);

  query.each(function(user) {
      var username = user.get('username');
      var feed = user.relation('feed');
      feed.remove(deletedVybe);
      return user.save();
  });
});


Parse.Cloud.job("removeDeletedVybesFromFeeds", function (request, status) {
  // Set up to modify user data
  Parse.Cloud.useMasterKey();

  // Query for all users
  var query = new Parse.Query(Parse.User);
  query.include('freshFeed');


  query.each(function(user) {
      var username = user.get('username');
      var freshFeed = user.get('freshFeed', []);
      var newFreshFeed = freshFeed.filter(function(vybe) { return vybe !== null; });
      var deleteCount = freshFeed.length - newFreshFeed.length;
      if (deleteCount) {
        console.log("Deleting " + deleteCount + " Vybes from " + username + "'s feed.");
        user.set('freshFeed', newFreshFeed);
        return user.save();
      }
  }).then(function() {
    // Set the job's success status
    status.success("Job completed successfully.");
  }, function(error) {
    // Set the job's error status
    status.error("Uh oh, something went wrong.");
  });
});

Parse.Cloud.job("removeOldVybesFromFeeds", function (request, status) {
  // Set up to modify user data
  Parse.Cloud.useMasterKey();

  // Query for all users
  var query = new Parse.Query(Parse.User);

  var ttlAgo = new Date(request.params.dateString);

  query.each(function(user) {
    var username = user.get('username');
    console.log('cleaning for ' + username);
    var feed = user.relation('feed');
    feed.query().find({
      success: function(list) {
        console.log('there are ' + list.length + ' feed for this user');
        for(i = 0; i < list.length; i++) {
          var aVybe = list[i];
          if (aVybe.get('timestamp') < ttlAgo) {
            feed.remove(aVybe);
          }
        }
        return user.save();
      },
      error: function(error) {
        console.log('failed clearing for user ' + user.get('username'));
        //return error;
      }
    });
  }).then(function() {
    // Set the job's success status
    status.success("Job completed successfully.");
  }, function(error) {
    // Set the job's error status
    status.error("Uh oh, something went wrong.");
  });
});


// Takes 3 arguments: vybeID of requesting vybe, zoneID of that vybe, and timestamp
Parse.Cloud.define('get_vybes_in_zone', function (request, response) {
  var zoneID = request.params.zoneID;
  var timestamp = request.params.timestamp;

  var query = new Parse.Query('Vybe');
  query.include('user');
  query.ascending('timestamp');
  query.greaterThanOrEqualTo('timestamp', timestamp);  // Ignore past vybes
  query.notEqualTo('isPublic', false);  // Don't get private vybes
  if (zoneID) {
    query.equalTo('zoneID', zoneID);
  } else {
    // Group untagged vybes together
    query.doesNotExist('zoneID');
  }

  query.find({
    success: function(vybesObjects) {
      console.log(vybesObjects.length + ' vybes found after this vybe in this zone');
      response.success(vybesObjects);
    },
    error: function() {
      response.error('Request to get_vybes_in_zone() has failed.');
    }
  });
});


// Takes 3 arguments: vybeID of requesting vybe, zoneID of that vybe, and timestamp
Parse.Cloud.define('get_count_for_zone', function (request, response) {
  var zoneID = request.params.zoneID;
  var timestamp = request.params.timestamp;

  var query = new Parse.Query('Vybe');
  query.include('user');
  query.ascending('timestamp');
  query.greaterThanOrEqualTo('timestamp', timestamp);  // Ignore past vybes
  query.notEqualTo('isPublic', false);  // Don't get private vybes
  if (zoneID) {
    query.equalTo('zoneID', zoneID);
  } else {
    // Group untagged vybes together
    query.doesNotExist('zoneID');
  }

  query.count({
    success: function(nearbyCount) {
      console.log(nearbyCount + ' vybes counted after this vybe in this zone');
      response.success(nearbyCount);
    },
    error: function() {
      response.error('Request to get_vybes() has failed.');
    }
  });
});


// Default algorithm used in the app
Parse.Cloud.define('get_active_zone_vybes', function (request, response) {
  var currTime = new Date();
  var aDayAgo = new Date();
  aDayAgo.setHours(currTime.getHours() - 24);  // 24 hour window

  var currUser = request.user;
  var blockedRelation = currUser.relation('blockedUsers');
  blockedRelation.query().find({
      success: function(list) {
        console.log('[get_active_zone_vybes] there are ' + list.length + ' blocked users for ' + currUser.get('username'));
        var query = new Parse.Query('Vybe');
        query.include('user')
        query.notContainedIn('user', list);
        query.addDescending('timestamp');
        var zoneID = request.params.zoneID;
        if (zoneID == '777') {
          query.doesNotExist('zoneID');
        }
        else {
          query.equalTo('zoneID', zoneID);
        }
        query.greaterThanOrEqualTo('timestamp', aDayAgo);

         query.find({
            success: function(vybesObjects) {
              console.log('active vybes found ' + vybesObjects.length);
              response.success(vybesObjects.reverse());  // Sort result in chronological order
            },
            error: function() {
              response.error('Request to get_active_zone_vybes() has failed.');
            }
        });
      },
      error: function(error) {
        response.error('[get_active_zone_vybes] failed getting blockedUsers for user ' + currUser.get('username'));
      }
    });
});


Parse.Cloud.define('get_active_vybes', function (request, response) {
  var currTime = new Date();
  var aDayAgo = new Date();
  aDayAgo.setHours(currTime.getHours() - 24);  // 24 hour window

  var currUser = request.user;
  var blockedRelation = currUser.relation('blockedUsers');
  blockedRelation.query().find({
      success: function(list) {
        console.log('there are ' + list.length + ' blocked users for ' + currUser.get('username'));
        var query = new Parse.Query('Vybe');
        query.include('user');
        query.notContainedIn('user', list);
        query.addDescending('timestamp');
        query.greaterThanOrEqualTo('timestamp',aDayAgo);
        query.limit(10000)

        query.find({
          success: function(vybesObjects) {
            console.log('active vybes found ' + vybesObjects.length);
            response.success(vybesObjects.reverse());  // Sort result in chronological order
          },
          error: function() {
            response.error('[get_active_vybes] Request to get_active_zone_vybes() has failed.');
          }
        });
      },
      error: function(error) {
        response.error('[get_active_vybes] failed getting blockedUsers for user ' + currUser.get('username'));
      }
    });

});


// Retrieve only fresh vybes for the requesting user
Parse.Cloud.define('get_fresh_vybes', function (request, response) {
  var currUser = request.user;
  var blockedRelation = currUser.relation('blockedUsers');
  var currTime = new Date();
  var aDayAgo = new Date();
  aDayAgo.setHours(currTime.getHours() - 24);  // 24 hour window.

   blockedRelation.query().find({
      success: function(list) {
        console.log('[get_fresh_vybes] there are ' + list.length + ' blocked users for ' + currUser.get('username'));
        var query = new Parse.Query(Parse.User);
        query.equalTo('username', currUser.get('username'));
        query.first({
          success: function(aUser) {
            var feed = aUser.relation('feed');
            var freshContents = [];
            var feedQuery = feed.query();
            feedQuery.include('user');
            feedQuery.notContainedIn('user', list);
            feedQuery.addAscending('timestamp');
            feedQuery.greaterThanOrEqualTo('timestamp', aDayAgo);
            feedQuery.find({
              success: function(list) {
                console.log('[get_fresh_vybes] There are ' + list.length + ' FRESH feed for ' + aUser.get('username'));
                response.success(list);
              },
              error: function(error) {
                response.error(error);
              }
            });
          },
          error: function(error) {
            response.error(error);
          }
        });
      },
      error: function(error) {
        response.error('[get_fresh_vybes] failed getting blockedUsers for user ' + currUser.get('username'));
      }
    });

});


Parse.Cloud.define('remove_from_feed', function (request, response) {
  var watchedObjID = request.params.vybeID;
  var currUser = request.user;

  var vybeQuery = new Parse.Query('Vybe');
  vybeQuery.equalTo('objectId', watchedObjID);
  vybeQuery.first({
    success: function(watchedObj) {
      var query = new Parse.Query(Parse.User);
      query.equalTo('username', currUser.get('username'));
      query.first({
        success: function(aUser) {
          console.log(aUser.get('username') + ' watched this vybe so lets delete');
          var feed = aUser.relation('feed');
          feed.remove(watchedObj);
          aUser.save();

          response.success(watchedObj);
        },
        error: function(error) {
          response.error(error);
        }
      });
    },
    error: function(error) {
      response.error(error);
    }
  });
});

Parse.Cloud.define('flag_vybe', function (request, response) {
  var flaggedContentID = request.params.vybeID;
  console.log(' Vybe(' + flaggedContentID + ') is FLAGGED ');

  var currUser = request.user;

  var query = new Parse.Query('Vybe');
  query.equalTo('objectId', flaggedContentID);
  query.first({
    success: function(flaggedObj) {
      console.log(currUser.get('username') + ' flagged ' + flaggedContentID);
      var flags = currUser.relation('flags');
      flags.add(flaggedObj);
      currUser.save();
      response.success(flaggedObj);
    },
    error: function(error) {
      response.error(error);
    }
  });
});

Parse.Cloud.define('unflag_vybe', function (request, response) {
  var unflaggedContentID = request.params.vybeID;
  console.log(' Vybe(' + unflaggedContentID + ') is UNFLAGGED ');

  var currUser = request.user;

  var query = new Parse.Query('Vybe');
  query.equalTo('objectId', unflaggedContentID);
  query.first({
    success: function(unflaggedObj) {
      console.log(currUser.get('username') + ' unflagged ' + unflaggedContentID);
      var flags = currUser.relation('flags');
      flags.remove(unflaggedObj);
      currUser.save();
      response.success(unflaggedObj);
    },
    error: function(error) {
      response.error(error);
    }
  });
});
