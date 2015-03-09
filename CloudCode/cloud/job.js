var _ = require('underscore');

Parse.Cloud.job('updateAllUsersFeed', function (request, status) {
  Parse.Cloud.useMasterKey();

  var query = new Parse.Query(Parse.User);
  var promises = [];

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
