
$(function() {

  Parse.$ = jQuery;

  Parse.initialize("gYVd0gSQavfnxcvIyFhns8j0KKyp0XHekKdrjJkC",
                   "ElJrtZZx480g2CrqVdJ7B6YPKRUBgIYGRzY5fMOa");


  var player = $('.video-container video').get(0);


  var Vybe = Parse.Object.extend("Vybe");

  var Playlist = Parse.Collection.extend({
    model: Vybe,

    zoneID: '5158db1fe4b00e2014fc2dda',

    initialize: function() {
      this.index = 0;

      this.query = new Parse.Query('Vybe')
        .descending('timestamp')
        .equalTo('zoneID', this.zoneID);

      this.fetch();
    },

    currentVybe: function() {
      return this.at(this.index);
    },

    next: function() {
      this.index += 1;
      if (this.index >= this.length) {
        this.index = 0;
      };
    }
  })


  var playlist = new Playlist();

  playlist.on('reset', function(playlist) {
    console.log('loaded playlist of length ' + playlist.length);

    playVideo();
  });

  player.addEventListener('ended', function () {
    playlist.next();

    playVideo();
  })

  var playVideo = function() {
    var currentVybe = playlist.currentVybe();

    player.src = currentVybe.get('video').url();
    player.poster = currentVybe.get('thumbnail').url();

    player.play();
    console.log('playing vybe number ' + playlist.index);
  }

});
