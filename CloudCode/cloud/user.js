// Check if username is set, and enforce uniqueness based on the username column.
Parse.Cloud.beforeSave(Parse.User, function(request, response) {
  var username = request.object.get("username");
  if (!username) {
    response.error('A User must have a username.');
  } else {
    var query = new Parse.Query(Parse.User);
    query.equalTo("username_lowercase", username.toLowerCase());
    query.first({
      success: function(object) {
        if (object) {
          response.error("A User with this username already exists.");
        } else {
          // Save a lowercase version of username to test for uniqueness
          request.object.set("username_lowercase", username.toLowerCase());
          response.success();
        }
      },
      error: function(error) {
        response.error("Could not validate uniqueness for this User object.");
      }
    });
  }
});
