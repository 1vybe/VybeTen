require('cloud/tribe');

var _ = require('underscore');
var Vybe = Parse.Object.extend('Vybe');

// Validate Vybes have a valid owner in the "user" pointer.
Parse.Cloud.beforeSave('Vybe', function(request, response) {
  var currentUser = request.user;
  var objectUser = request.object.get('user');

  if(!currentUser || !objectUser) {
    response.error('A Vybe should have a valid user.');
  } else if (currentUser.id === objectUser.id) {
    response.success();
  } else {
    response.error('Cannot set user on Vybe to a user other than the current user.');
  }
});

Parse.Cloud.afterSave('Vybe', function(request) {
  // Only send push notifications for new vybes
  if (request.object.existed()) {
    return;
  }

  // Send iOS push notifications to tribe members
  if (request.user.has('tribe')) {
    sendPush(request);
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
  var query = new Parse.Query(Parse.User);
  query.notEqualTo('username', request.user.get('username'));
  query.find().then(function(users) {
    Parse.Cloud.useMasterKey();
    console.log('lets feed to ' + users.length + ' users');
    _.each(users, function(aUser) {
      var feed = aUser.get('freshFeed');
      if (!feed) {
        feed = [];
      }

      feed.push(request.object);
      aUser.set('freshFeed', feed);
      aUser.save();
    });
  });


});

Parse.Cloud.job("removeDeletedVybesFromFeeds", function(request, status) {
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

Parse.Cloud.afterDelete("Vybe", function(request) {
  // Set up to modify user data
  Parse.Cloud.useMasterKey();

  var deletedVybe = request.object;

  // Query for all users
  var query = new Parse.Query(Parse.User);
  query.include('freshFeed');
  query.equalTo('freshFeed', deletedVybe);
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

var sendPush = function(request) {
  var user = request.object.get("user");
  if (!user) {
    throw "Undefined user. Skipping push for Vybe " +
          request.object.id;
  }

  var currentUser = Parse.User.current();

  var query = new Parse.Query(Parse.User);

  var relation = currentUser.get('tribe').relation('members');
  relation.query().find().then(function(members) {

    var query = new Parse.Query(Parse.Installation);
    query.containedIn('user', members);
    query.notEqualTo('user', currentUser);
    Parse.Push.send({
      where: query, // Set our Installation query.
      data: alertPayload(request)
    }).then(function() {
      // Push was successful
      console.log('Sent push.');
    }, function(error) {
      throw "Push Error " + error.code + " : " + error.message;
    });
  });
};

var alertMessage = function(request) {
  var message = "";

  message = "Someone in your tribe posted a vybe.";

  // Trim our message to 140 characters.
  if (message.length > 140) {
    message = message.substring(0, 140);
  }

  return message;
};

var alertPayload = function(request) {
  var payload = {};
  return {
    alert: alertMessage(request), // Set our alert message.
    sound: '',
    badge: 'Increment', // Increment the target device's badge count.
    vid: request.object.id, // Vybe Id
  };
};

// Function that returns info about regions
Parse.Cloud.define('get_regions', get_regions);

// Default algorithm used in the app
Parse.Cloud.define('default_algorithm',
  get_vybes.bind(this, {
    recent: true,
    reversed: true,
  })
);

// Retrieve only fresh vybes for the requesting user
Parse.Cloud.define('get_fresh_vybes', get_fresh_vybes);

Parse.Cloud.define('remove_from_feed', remove_from_feed);

// Retrieve vybes by city
Parse.Cloud.define('get_region_vybes',
  get_region_vybes.bind(this, {
    recent:true,
    reversed:true,
  })
);

// Algorithms that can be chosen from the debug menu
Parse.Cloud.define('algorithm1',
  get_vybes.bind(this, {
    recent: true,
    reversed: true,
  })
);
Parse.Cloud.define('algorithm2',
  get_vybes.bind(this, {
    recent: true,
    reversed: true,
    hide_user: true,
  })
);
Parse.Cloud.define('algorithm3',
  get_vybes.bind(this, {
    recent: true,
    nearby: true,
    hide_user: true,
  })
);

Parse.Cloud.define('get_tribe_vybes',
  get_tribe_vybes.bind(this, {
    recent: true,
    reversed: true,
  })
);

function get_fresh_vybes(request, response) {
  var currUser = request.user;
  var query = new Parse.Query(Parse.User);

  query.include('freshFeed');
  query.equalTo('username', currUser.get('username'));
  query.first({
    success: function(aUser) {
      var freshVybes = aUser.get('freshFeed');
      if (!freshVybes)
        freshVybes = [];
      response.success(freshVybes);
    },
    error: function(error) {
      response.error(error);
    }
  });
}

function remove_from_feed(request, response) {
  var wVybeID = request.params.vybeID;
  var currUser = request.user;
  var query = new Parse.Query(Parse.User);

  query.equalTo('username', currUser.get('username'));
  query.first({
    success: function(aUser) {
      var oldFreshVybes = aUser.get('freshFeed');
      if (oldFreshVybes) {
        var newFreshVybes = [];
        _.each(oldFreshVybes, function(oVybe) {
          if (oVybe.id != wVybeID) {
            newFreshVybes.push(oVybe);
          } else {
            console.log('removed from feed!');
          }
        });
        aUser.set('freshFeed', newFreshVybes);
        aUser.save();
      }
      response.success(wVybeID);
    },
    error: function(error) {
      response.error(error);
    }
  });
}

function get_regions(request, response) {
  var regions = [];
  var preQuery = new Parse.Query('Region');

  preQuery.find().then(function(regionObjs) {
    var promise = Parse.Promise.as();
    _.each(regionObjs, function(regionObj) {
      var query = new Parse.Query('Vybe');
      var countryCode = regionObj.get('code');
      //NOTE: this limit is max but should be disregarded
      query.limit(1000);
      query.equalTo('countryCode', countryCode);
      query.notEqualTo('isPublic', false);
      // 24 hour TTL check
      var currTime = new Date();
      var ttlAgo = new Date();
      ttlAgo.setHours(currTime.getHours() - 24);
      query.greaterThanOrEqualTo('timestamp',ttlAgo);
      query.notEqualTo('user', request.user);
      query.include('user');
      promise = promise.then(function() {
        return query.count().then(function(vCount) {
          if (vCount < 1)
            return;
          var userQuery = new Parse.Query(Parse.User);
          //NOTE: this limit is max but should be disregarded
          userQuery.limit(1000);
          userQuery.exists('mostRecentVybe');
          userQuery.matchesQuery('mostRecentVybe', query);
          userQuery.notEqualTo('username', request.user.get('username'));
          //NOTE: we do NOT check TTL for couting active users.
          return userQuery.count().then(function(uCount) {
            var mRegion = {};
            mRegion.pfRegion = regionObj;
            mRegion.vybeCount = vCount;
            mRegion.userCount =  uCount;
            regions.push(mRegion);
          });
        });
      });
    });
    return promise;
  }).then(function() {
    response.success(regions);
  });
}

function count_distinct_user(vybeObjs) {
  if (vybeObjs.length === 0)
    return 0;
  var users = {};
  for (i = 0; i < vybeObjs.length; i++) {
    var aVybe = vybeObjs[i];
    var newUser = aVybe.get('user');
    if (newUser)
      console.log('new user objID: ' + aVybe.id);
    users[newUser.get('username')] = "c";
  }

  return Object.keys(users).length;
}


// Generic get_vybes functions that accepts options
function get_vybes(options, request, response) {
  var recent = options.recent || false;
  var nearby = options.nearby || false;
  var hide_user = options.hide_user || false;
  var reversed = options.reversed || false;
  var limit = options.limit || 500;

  var geoPoint = request.params.location;

  var currentUser = Parse.User.current();

  var query = new Parse.Query('Vybe');
  query.include('user');

  if (recent)
    query.addDescending('timestamp');
  if (nearby)
    query.near('location', geoPoint);
  if (hide_user)
    query.notEqualTo('user', currentUser);
  if (limit)
    query.limit(limit);

  // Don't get private vybes
  query.notEqualTo('isPublic', false);
  // 24 hour TTL check
  var currTime = new Date();
  var ttlAgo = new Date();
  ttlAgo.setHours(currTime.getHours() - 24);
  query.greaterThanOrEqualTo('timestamp',ttlAgo);
  query.find({
    success: function(vybesObjects) {
      if (reversed) {
        response.success(vybesObjects);
      } else {
        // Sort result in chronological order
        response.success(vybesObjects.reverse());
      }
    },
    error: function() {
      response.error('Request to get_vybes() has failed.');
    }
  });
}

function get_region_vybes(options, request, response) {
  var recent = options.recent || false;
  var hide_user = options.hide_user || false;
  var reversed = options.reversed || false;
  var limit = options.limit || 500;

  var currentUser = Parse.User.current();

  var Region = Parse.Object.extend('Region');
  var currRegion = new Region();
  currRegion.id = request.params.regionID;

  var query = new Parse.Query('Vybe');
  query.include('user');
  if (recent)
    query.addDescending('timestamp');
  if (hide_user)
    query.notEqualTo('user', currentUser);
  if (limit)
    query.limit(limit);
  // Don't get private vybes
  query.notEqualTo('isPublic', false);
  // 24 hour TTL check
  var currTime = new Date();
  var ttlAgo = new Date();
  ttlAgo.setHours(currTime.getHours() - 24);
  query.greaterThanOrEqualTo('timestamp',ttlAgo);

  currRegion.fetch({
    success: function(region) {
      var countryCode = region.get('code');
      query.equalTo('countryCode', countryCode);
      query.find({
        success: function(vybesObjects) {
          if (reversed) {
            response.success(vybesObjects);
          } else {
            // Sort result in chronological order
            response.success(vybesObjects.reverse());
          }
        },
        error: function(error) {
          response.error('Request to get_city_vybes() has failed: ' + error.code);
        }
      });
    },
    error: function(error) {
      response.error('Unable to access city info.');
    }
  });
}

// Generic get_tribe_vybes functions that accepts options
function get_tribe_vybes(options, request, response) {
  var recent = options.recent || false;
  var nearby = options.nearby || false;
  var hide_user = options.hide_user || false;
  var limit = options.limit || 500;

  var userGeoPoint = request.params.location;
  var startTime = request.params.startTime;
  var currentUser = Parse.User.current();

  if (!currentUser.get('tribe')) {
    // TODO: Create a tribe for this user
    response.error('This user is not a member of a tribe.');
  }

  var relation = currentUser.get('tribe').relation('members');
  var query = new Parse.Query(Parse.User);
  relation.query().find().then(function(members) {

    var query = new Parse.Query('Vybe');
    query.include('user');
    query.containedIn('user', members);

    if (recent)
      query.addDescending('timestamp');
    if (nearby)
      query.near('location', userGeoPoint);
    if (hide_user)
      query.notEqualTo('user', currentUser);
    if (limit)
      query.limit(limit);
    if (startTime)
      query.greaterThan("timestamp", startTime);

    query.find({
      success: function(vybesObjects) {
        if (!startTime) {
          response.success(vybesObjects);
        } else {
          // Sort result in chronological order
          response.success(vybesObjects.reverse());
        }
      },
      error: function() {
        response.error('Request to get_tribe_vybes() has failed.');
      }
    });
  });
}
