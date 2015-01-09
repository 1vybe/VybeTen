
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
        .descending('timestamp')
        .limit(1000);

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

    prev: function() {
      this.index -= 1;
      if (this.index < 0) {
        this.index = this.length - 1;
      };
    },

    comparator: function(vybe) {
      return vybe.get('timestamp');
    }
  })


  var PlayerView = Parse.View.extend({

    el: $('.player').get(0),

    initialize: function() {
      _.bindAll(this, 'render', 'playNext', 'playPrev', 'logKey');

      this.player = $('.player').get(0);

      this.overlay = $('.overlay.info');

      this.preloader = $('.preloader').get(0);

      this.playlist = new Playlist;
      this.playlist.bind('reset', this.render);

      state.on("change", this.changeChannel, this);

      $('body').keydown(this.logKey);
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

      // Don't do anything if there are no vybes
      if (currentVybe === undefined) return;

      var zoneName = currentVybe.get('zoneName');
      if (!zoneName) zoneName = 'Earth';
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
    },

    playPrev: function() {
      this.playlist.prev();

      this.render();
    },

    logKey: function(e) {
      if([32, 37, 38, 39, 40].indexOf(e.keyCode) > -1) {
        e.preventDefault();
        switch (e.keyCode) {
          case 39: this.playNext(); break;
          case 37: this.playPrev(); break;
        }
      }
    }
  });


  var AppRouter = Parse.Router.extend({

    routes: {
      "all": "all",
      "stereo": "stereo",
      "regency": "regency",
      "mmelee": "mmelee",
      "13percent": "thirteenPercent",
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

    thirteenPercent: function() {
      state.set({
        location: 'Le Salon Daomé',
        time: '2015-01-09T04:00:00.000Z'
      });
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
