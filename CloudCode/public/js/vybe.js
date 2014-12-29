
$(function() {

  Parse.$ = jQuery;

  Parse.initialize("gYVd0gSQavfnxcvIyFhns8j0KKyp0XHekKdrjJkC",
                   "ElJrtZZx480g2CrqVdJ7B6YPKRUBgIYGRzY5fMOa");


  var Vybe = Parse.Object.extend("Vybe");


  var Playlist = Parse.Collection.extend({
    model: Vybe,

    initialize: function() {
      this.index = 0;

      this.setLocation('New City Gas');
    },

    setLocation: function(location) {
      this.location = location;

      this.query = new Parse.Query('Vybe')
        .descending('timestamp');

      if (location)
        this.query.equalTo('zoneName', this.location);
    },

    currentVybe: function() {
      return this.at(this.index);
    },

    nextVybe: function() {
      var nextIndex = this.index + 1;
      if (nextIndex >= this.length) {
        nextIndex = 0;
      };
      return this.at(nextIndex);
    },

    next: function() {
      this.index += 1;
      if (this.index >= this.length) {
        this.index = 0;
        this.fetch();
      };
    },

    comparator: function(vybe) {
      return vybe.get('timestamp');
    }
  })


  var player = $('.video-container video').get(0);
  var preloader = $('.invisible.preload video').get(0);

  var PlayerView = Parse.View.extend({
    el: $('.video-container video').get(0),

    initialize: function() {
      this.player = $('.video-container video').get(0);
      this.preloader = $('.invisible.preload video').get(0);

      this.playlist = new Playlist;

      _.bindAll(this, 'render', 'playNext');
      this.playlist.bind('reset', this.playNext);
      this.playlist.fetch();
    },
    events: {
      'ended': 'playNext',
    },
    render: function() {

    },
    playNext: function() {
      this.playlist.next();

      var currentVybe = this.playlist.currentVybe();
      var nextVybe = this.playlist.nextVybe();

      this.player.src = currentVybe.get('video').url();
      this.player.poster = currentVybe.get('thumbnail').url();

      this.preloader.src = nextVybe.get('video').url();

      this.player.play();
      return this;
    }
  });

  var AppRouter = Parse.Router.extend({

    initialize: function() {
      this.player = new PlayerView;
    },

    routes: {
      "*path": "changeLocation"
    },

    changeLocation: function(zone) {
      var location = 'New City Gas';

      switch(zone) {
        case 'stereo':
          location = 'Stereo Night Club';
          break;
        case 'regency':
          location = 'Le Regency';
          break;
        case 'mmelee':
          location = 'Mme Lee';
          break;
        case 'all':
          location = '';
          break;
      }

      this.player.playlist.setLocation(location);
      this.player.playlist.fetch();
    }
  });

  new AppRouter;
  Parse.history.start();
});
