
var _ = require('underscore');
var Vybe = Parse.Object.extend('Vybe');
var Activity = Parse.Object.extend('Activity')

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

Parse.Cloud.job('updateAllUsersFeed', function (request, status) {
  Parse.Cloud.useMasterKey();

  var query = new Parse.Query(Parse.User);
  var promises = [];
  status.message('LET\'s FEED!!!!!!!!!!');

  query.each(function(user) {
    var feed = user.relation('feed');
    feed.add(request.object);
    promises.push(user.save());
  });

  return Parse.Promise.when(promises).then(function () {
    status.success('Everyone\'s feed is updated');
  }, function (error) {
    status.error('Error occured updating everyone\'s feed.  ' + error.code);
  });
});

Parse.Cloud.afterSave('Vybe', function (request) {
  // Continue only for new vybes
  if (request.object.existed()) {
    return;
  }

  // Run a background job to push a new vybe into everyone's feed
  Parse.Cloud.httpRequest({
    method: 'POST',
    url: 'https://api.parse.com/1/jobs/updateAllUsersFeed',
    headers: {
      'Content-Type' : 'application/json',
      'X-Parse-Application-Id' : 'gYVd0gSQavfnxcvIyFhns8j0KKyp0XHekKdrjJkC',
      'X-Parse-Master-Key' : 'OgzdYpZf8z99FCbmwHHr6WheKe45p5pv7qOChHmk'
    },
    body: {
      'request' : request
    },
    success: function (httpResponse) {
      console.log('Job Success: ' + httpResponse.text);
    },
    error: function (httpResponse) {
      console.log('Job Failed: (code) ' + httpResponse.status)
    }
  });

  // Send push
  var tribe = request.object.get('tribe');
  tribe.fetch().then(function (tribeObj) {
    var userQuery = tribe.relation('members').query();
    userQuery.notEqualTo('username', request.user.get('username'));

    var query = new Parse.Query(Parse.Installation);
    query.matchesQuery('user', userQuery)
    
    var alertMessage = request.user.get('username') + ' vybed in ' + tribeObj.get('name');
    var pushPayload = {
      alert: alertMessage, // Set our alert message.
      p: 'v', // Payload Type: Vybe
      tid: tribe.id // Tribe Id
    }
    console.log('Sending Vybe Push : ' + alertMessage);


    Parse.Push.send({
      where: query,
      data: pushPayload
    }).then(function() {
      console.log('Sent Vybe Push : ' + alertMessage);
    }, function(error) {
      throw error.code + ' : ' + error.message;
    });
  });
});

Parse.Cloud.afterDelete('Vybe', function (request) {
  // Set up to modify user data
  Parse.Cloud.useMasterKey();

  var deletedVybe = request.object;

  // Delete all activities that have a reference to the deleted vybe
  var activityQuery = new Parse.Query('Activity')
  activityQuery.equalTo('vybe', deletedVybe)
  activityQuery.each(function(activity) {
    return activity.destroy();
  });

  // Delete from all users feed
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

Parse.Cloud.job("resetUserPromptsSeen", function (request, status) {
  // Set up to modify user data
  Parse.Cloud.useMasterKey();

    // Query for all users
  var query = new Parse.Query(Parse.User);
  query.each(function(user) {
    user.set('resetUserPromptsSeen', false);
    return user.save();
  }).then(function() {
    status.success("Job completed");
  }, function(error) {
    status.error("Job failed");
  });
});
// This job takes one parameter in a format - {"dateString": "2014-12-10T23:00:00Z"}
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
    var feedQuery = feed.query();
    feedQuery.limit(1000);
    return feedQuery.find({
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

;
