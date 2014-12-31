
$(function() {

  Parse.$ = jQuery;

  Parse.initialize("gYVd0gSQavfnxcvIyFhns8j0KKyp0XHekKdrjJkC",
                   "ElJrtZZx480g2CrqVdJ7B6YPKRUBgIYGRzY5fMOa");


  var Vybe = Parse.Object.extend("Vybe");


  var Playlist = Parse.Collection.extend({
    model: Vybe,

    initialize: function() {
      this.index = 0;
    },

    setChannel: function(location, time) {
      this.location = location;
      this.time = time;

      this.query = new Parse.Query('Vybe')
        .descending('timestamp');

      if (location) this.query.equalTo('zoneName', this.location);
      if (time) this.query.greaterThanOrEqualTo('timestamp', new Date(this.time));
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


  var PlayerView = Parse.View.extend({

    el: $('.player').get(0),

    initialize: function() {
      _.bindAll(this, 'render', 'playNext');

      this.player = $('.player').get(0);

      this.overlay = $('.overlay');

      this.preloader = $('.preloader').get(0);

      this.playlist = new Playlist;
      this.playlist.bind('reset', this.render);

      state.on("change", this.changeChannel, this);
    },

    events: {
      'ended': 'playNext',
    },

    changeChannel: function() {
      var location = state.get('location');
      var time = state.get('time');

      this.playlist.setChannel(location, time);
      this.playlist.fetch();
    },

    render: function() {
      var currentVybe = this.playlist.currentVybe();
      var nextVybe = this.playlist.nextVybe();

      var zoneName = currentVybe.get('zoneName');
      var timestamp = currentVybe.get('timestamp');
      var formattedTimestamp = moment(timestamp).format('MMM DD h:mm a');

      this.overlay.html(zoneName + '<br>' + formattedTimestamp);

      this.player.src = currentVybe.get('video').url();
      this.player.poster = currentVybe.get('thumbnail').url();

      this.preloader.src = nextVybe.get('video').url();

      this.player.play();
    },

    playNext: function() {
      this.playlist.next();

      this.render();
    }
  });


  var AppRouter = Parse.Router.extend({

    routes: {
      "all": "all",
      "stereo": "stereo",
      "regency": "regency",
      "mmelee": "mmelee",
      "*path": "newyears",
    },

    all: function() {
      state.set({ location: '' });
    },

    stereo: function() {
      state.set({ location: 'Stereo Night Club' });
    },

    regency: function() {
      state.set({ location: 'Le Regency' });
    },

    mmelee: function() {
      state.set({ location: 'Mme Lee' });
    },

    newyears: function() {
      state.set({ location: '', time: '2014-12-31T10:00:00.000Z' });
    },

    default: function() {
      state.set({ location: 'New City Gas' });
    }

  });

  var AppState = Parse.Object.extend('AppState');


  var state = new AppState;

  new AppRouter;
  new PlayerView;

  Parse.history.start();
});
