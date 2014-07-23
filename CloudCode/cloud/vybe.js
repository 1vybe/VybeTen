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

// Sends a Yo to all who Yo VybeDev
Parse.Cloud.afterSave('Vybe', function(request) {
  // Only send push notifications for new vybes
  if (request.object.existed()) {
    return;
  }

  Parse.Cloud.httpRequest({
    method: 'POST',
    url: 'http://api.justyo.co/yoall/',
    body: {
      api_token: '04d36172-8b8a-4075-063d-5a163e13e351',
    },
    success: function(httpResponse) {
      console.log('Sent a Yo!');
    },
    error: function(httpResponse) {
      console.error('Request failed with response code ' + httpResponse.status);
    }
  });
});

// Default algorithm used in the app
Parse.Cloud.define('default_algorithm',
    get_vybes.bind(this, {
        recent: true,
        reversed: true,
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

// Generic get_vybes functions that accepts options
function get_vybes(options, request, response) {
  var recent = options.recent || false;
  var nearby = options.nearby || false;
  var hide_user = options.hide_user || false;
  var reversed = options.reversed || false;
  var limit = options.limit || 10;

  var userGeoPoint = request.params.location;
  var currentUser = Parse.User.current();

  var query = new Parse.Query('Vybe');

  if (recent)
    query.addDescending('timestamp');
  if (nearby)
    query.near('location', userGeoPoint);
  if (hide_user)
    query.notEqualTo('user', currentUser);
  if (limit)
    query.limit(limit);

  // Don't get private vybes
  query.notEqualTo('isPublic', false);

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

// Generic get_tribe_vybes functions that accepts options
function get_tribe_vybes(options, request, response) {
  var recent = options.recent || false;
  var nearby = options.nearby || false;
  var hide_user = options.hide_user || false;
  var reversed = options.reversed || false;
  var limit = options.limit || 10;

  var userGeoPoint = request.params.location;
  var currentUser = Parse.User.current();

  var query = new Parse.Query(Parse.User);

  var relation = currentUser.get('tribe').relation('members');
  relation.query().find().then(function(members) {

    var query = new Parse.Query('Vybe');

    query.containedIn('user', members);

    if (recent)
      query.addDescending('timestamp');
    if (nearby)
      query.near('location', userGeoPoint);
    if (hide_user)
      query.notEqualTo('user', currentUser);
    if (limit)
      query.limit(limit);

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
        response.error('Request to get_tribe_vybes_new() has failed.');
      }
    });
  });
}
