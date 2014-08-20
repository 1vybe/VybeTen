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

// Sends a Yo to all who Yo VybeDev
Parse.Cloud.afterSave('Vybe', function(request) {
  // Only send push notifications for new vybes
  if (request.object.existed()) {
    return;
  }

  // Send iOS push notifications to tribe members
  if (request.user.has('tribe')) {
    console.log("This dude's got a tribe.");
    sendPush(request);
  }

  // Send Yo's for public vybes
  if (request.object.get('isPublic')) {
    console.log("This vybe is public. Sending a Yo.");
    sendYo();
  }
});

var sendYo = function() {
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
};

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

// Retrive vybes by city
Parse.Cloud.define('get_city_vybes',
		   get_city_vybes.bind(this, {
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

function get_regions(request, response) {
  console.log('CP1');
  var regions = [];
  var preQuery = new Parse.Query('Region');

  preQuery.find().then(function(regionObjs) {
    var promise = Parse.Promise.as();
    _.each(regionObjs, function(regionObj) {
      var query = new Parse.Query('Vybe');
      var countryCode = regionObj.get('code');
      query.limit(1000);
      query.equalTo('countryCode', countryCode);
//      query.notEqualTo('isPublic', false);
      query.include('user');
      promise = promise.then(function() {
	return query.find().then(function(vybes) {
	  var vybeCount = vybes.length;
	  console.log('Region: ' + regionObj.get('name'));
	  console.log('There are ' + vybeCount + ' vybes');
	  var userCount = count_distinct_user(vybes);
	  var mRegion = {};
	  mRegion['pfRegion'] = regionObj;
	  mRegion['vybeCount'] = vybeCount;
	  mRegion['userCount'] =  userCount;
	  regions.push(mRegion);
	});
      });
    });
    return promise;

  }).then(function() {
    console.log('regions successfully returned');
    response.success(regions);
  });

}

function count_distinct_user(vybeObjs) {
  if (vybeObjs.length == 0)
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

function get_city_vybes(options, request, response) {
  var recent = options.recent || false;
  var hide_user = options.hide_user || false;
  var reversed = options.reversed || false;
  var limit = options.limit || 500;

  var currentUser = Parse.User.current();

  var City = Parse.Object.extend('City');
  var currCity = new City();
  currCity.id = request.params.cityID;

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

  currCity.fetch({
    success: function(city) {
      var lat = city.get('swLatitude') * 1.0;
      var lon = city.get('swLongitude') * 1.0;
      var swPoint = new Parse.GeoPoint(lat, lon);

      lat = city.get('neLatitude') * 1.0;
      lon = city.get('neLongitude') * 1.0;
      var nePoint = new Parse.GeoPoint(lat, lon);
      query.withinGeoBox('location', swPoint, nePoint);
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
