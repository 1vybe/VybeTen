// Sends a Yo to all who Yo VybeDev
Parse.Cloud.afterSave("Vybe", function(request) {
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
