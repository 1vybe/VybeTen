// Check if username is set, and enforce uniqueness based on the username column.
Parse.Cloud.beforeSave(Parse.User, function(request, response) {
  var username = request.object.get("username");
  if (!username) {
    response.error('A User must have a username.');
  } else {
    var errorMsg = validateUsername(username);
    if (errorMsg !== "") {
      response.error(errorMsg);
    } else {
      var query = new Parse.Query(Parse.User);
      query.equalTo("username_lowercase", username.toLowerCase());
      query.first({
        success: function(object) {
          if (object) {
            if (request.object.existed()) {
              response.success();
            } else {
              response.error("A User with this username already exists.");
            }
          } else {
            // Save a lowercase version of username to test for uniqueness
            request.object.set("username_lowercase", username.toLowerCase());
            response.success();
          }
        },
        error: function(error) {
          response.error(error);
        }
      });
    }
  }
});

function validateUsername(username) {
  if (username.length < 2 || username.length > 13) {
    return "A username should be between 3 - 13 characters.";
  }

  if (!/^\w+$/.test(username)) {
    return "A username should only include alphanumeric characters and underscore.";
  }

  return "";
}
