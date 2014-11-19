require('cloud/tribe');

var _ = require('underscore');
var Vybe = Parse.Object.extend('Vybe');


// Validate Vybes have a valid owner in the "user" pointer.
Parse.Cloud.beforeSave('Vybe', function (request, response) {
  var objectUser = request.object.get('user');

  if(!objectUser) {
    response.error('A Vybe should have a valid user.');
  } else {
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
  query.include('freshFeed');
  query.each(function(user) {
    console.log('feeding to ' + user.get('username'));

    var feed = user.get('freshFeed', []);
    if (feed === null) {
      feed = [request.object];
      console.log('first entry to feed!');
    }
    else {
      console.log('feed already has ' + feed.length + 'vybes');
      feed.push(request.object);
    }
    user.set('freshFeed', feed);
    console.log('successfully fed to ' + user.get('username'));

    user.save();
  });

});


Parse.Cloud.afterDelete('Vybe', function (request) {
  // Set up to modify user data
  Parse.Cloud.useMasterKey();

  var deletedVybe = request.object;

  // Query for all users
  var query = new Parse.Query(Parse.User);
  query.equalTo('freshFeed', deletedVybe);
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
  query.exists('freshFeed');
  query.include('freshFeed');

  var ttlAgo = new Date('2014-11-15T23:00:00Z'); // Temporary time interval (UTC)

  query.each(function(user) {
    var username = user.get('username');
    console.log('cleaning for ' + username);
    var freshFeed = user.get('freshFeed', []);
    if (freshFeed !== null) {
      var newFreshFeed = freshFeed.filter(function(vybe) { return vybe !== null; });
      newFreshFeed = newFreshFeed.filter(function(vybe) { return vybe.get('timestamp') > ttlAgo; });
      var deleteCount = freshFeed.length - newFreshFeed.length;
      if (deleteCount) {
        console.log("Deleting " + deleteCount + " Vybes from " + username + "'s feed.");
        user.set('freshFeed', newFreshFeed);
        return user.save();
      }
    }
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
  query.include('freshFeed');

  query.first({
    success: function(aUser) {
      var currTime = new Date();
      //var ttlAgo = new Date('2014-11-15T23:00:00Z'); // Temporary time interval (UTC)
      var ttlAgo = new Date();
      ttlAgo.setHours(currTime.getHours() - 24);  // 24 hour window
      
      var feed = aUser.get('freshFeed');
      var feedIds = [];

      if (feed) {
        console.log('There are ' + feed.length + ' feed for ' + aUser.get('username'));
        for (i = 0; i < feed.length; i++) {
          var aVybe = feed[i];
          if (aVybe != null) {
            feedIds.push(aVybe.id);
          }
        }

        var vybeQuery = new Parse.Query('Vybe');
        vybeQuery.include('user')
        vybeQuery.greaterThanOrEqualTo('timestamp', ttlAgo);
        vybeQuery.containedIn('objectId', feedIds);
        console.log('There are ' + feedIds.length + ' feedIds');
        vybeQuery.find({
          success: function(freshObjs) {
            console.log('There are ' + freshObjs.length + ' fresh vybes for ' + aUser.get('username'));
            response.success(freshObjs);
          },
          error: function(error) {
            console.log('Fetching fresh feed failed: ' + error);
          }
        });
      }
      else {
        response.error('There is no feed for ' + aUser.username)
      }
    },
    error: function(error) {
      response.error(error);
    }
  });
});


Parse.Cloud.define('remove_from_feed', function (request, response) {
  var wVybeID = request.params.vybeID;
  var currUser = request.user;

  var query = new Parse.Query(Parse.User);
  query.equalTo('username', currUser.get('username'));

  query.first({
    success: function(aUser) {
      var oldFeed = aUser.get('freshFeed');
      if (oldFeed) {
        var newFeed = [];
        for (i = 0; i < oldFeed.length; i++) {
          var oVybe = oldFeed[i];
          if (oVybe.id == wVybeID) {
            console.log("Found the old vybe!!!!");
          }
          else {
            newFeed.push(oVybe);
          }
        }
        aUser.set('freshFeed', newFeed);
        aUser.save();
        response.success(wVybeID);
      }
      else {
        response.error('removing failed because there is no feed for user ' + currUser.get('username'));
      }
    },
    error: function(error) {
      response.error(error);
    }
  });
});
