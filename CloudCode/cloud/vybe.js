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
    response.error('duplicate vybe posted');
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
  //var ttlAgo = new Date('2014-11-15T23:00:00Z'); // Temporary time interval (UTC)
  var ttlAgo = new Date();
  ttlAgo.setHours(currTime.getHours() - 24);  // 24 hour window

  var query = new Parse.Query('Vybe');
  query.include('user')
  query.addDescending('timestamp');
  var zoneID = request.params.zoneID;
  if (zoneID == '777') {
    query.doesNotExist('zoneID');
  }
  else {
    query.equalTo('zoneID', zoneID);
  }
  query.greaterThanOrEqualTo('timestamp', ttlAgo);

   query.find({
      success: function(vybesObjects) {
        console.log('active vybes found ' + vybesObjects.length);
        response.success(vybesObjects.reverse());  // Sort result in chronological order
      },
      error: function() {
        response.error('Request to get_active_zone_vybes() has failed.');
      }
  });
});


Parse.Cloud.define('get_active_vybes', function (request, response) {
  var currTime = new Date();
  //var ttlAgo = new Date('2014-11-15T23:00:00Z');
  var ttlAgo = new Date();
  ttlAgo.setHours(currTime.getHours() - 24);  // 24 hour window


  var query = new Parse.Query('Vybe');
  query.include('user')
  query.addDescending('timestamp');
  query.greaterThanOrEqualTo('timestamp',ttlAgo);

  query.find({
    success: function(vybesObjects) {
      console.log('active vybes found ' + vybesObjects.length);
      response.success(vybesObjects.reverse());  // Sort result in chronological order
    },
    error: function() {
      response.error('Request to get_active_zone_vybes() has failed.');
    }
  });
});


// Retrieve only fresh vybes for the requesting user
Parse.Cloud.define('get_fresh_vybes', function (request, response) {
  var currUser = request.user;

  var query = new Parse.Query(Parse.User);
  query.equalTo('username', currUser.get('username'));

  query.first({
    success: function(aUser) {
      var currTime = new Date();
      //var ttlAgo = new Date('2014-11-15T23:00:00Z'); // Temporary time interval (UTC)
      var ttlAgo = new Date();
      ttlAgo.setHours(currTime.getHours() - 24);  // 24 hour window.
      
      var feed = aUser.relation('feed');
      var freshContents = [];
      var feedQuery = feed.query();
      feedQuery.include('user');
      feedQuery.addAscending('timestamp');
      feedQuery.find({
        success: function(list) {
          console.log('There are ' + list.length + ' feed for ' + aUser.get('username'));
          for (i = 0; i < list.length; i++) {
            var aVybe = list[i];
            if (aVybe.get('timestamp') > ttlAgo) {
              freshContents.push(aVybe);
            }
          }
          response.success(freshContents);
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
