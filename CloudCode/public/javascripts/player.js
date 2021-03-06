
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
      this.query = new Parse.Query('Vybe')
        .descending('timestamp')
        .limit(1000)
        .include('user');

      this.location = location;
      this.time = time;

      if (this.location)
        this.query.equalTo('zoneName', this.location);
      if (this.time)
        this.query.greaterThanOrEqualTo('timestamp', new Date(this.time));
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

    el: '#liveplayer',

    initialize: function() {
      var self = this;

      _.bindAll(this, 'render', 'playNext', 'playPrev', 'logKey');

      this.$el.html(_.template($("#liveplayer-template").html()));

      // video element does not propogate events up the DOM
      var video = $(self.el).find("video.player");
      video.on('ended', function(e){
          $(self.el).trigger('playerEnded');
      });

      this.player = this.$('.player').get(0);

      this.info = this.$('.info');

      this.preloader = this.$('.preloader').get(0);

      this.playlist = new Playlist;
      this.playlist.bind('reset', this.render);

      state.on("change", this.changeChannel, this);

      $('body').keydown(this.logKey);
    },

    events: {
      'playerEnded': 'playNext',
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

      var user = currentVybe.get('user');
      var username = user.get('username');

      var zoneName = currentVybe.get('zoneName');
      if (!zoneName) zoneName = 'Earth';

      var timestamp = currentVybe.get('timestamp');
      var formattedTimestamp = moment(timestamp).format('MMM DD h:mm a');

      this.info.html([username, zoneName, formattedTimestamp].join('<br>'));

      this.preloader.src = nextVybe.get('video').url();

      this.player.src = currentVybe.get('video').url();
      this.player.poster = currentVybe.get('thumbnail').url();
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

    pause: function() {
      if (!this.player.paused) {
        this.player.pause();
      } else {
        this.player.play();
      }
    },

    logKey: function(e) {
      if([32, 37, 38, 39, 40].indexOf(e.keyCode) > -1) {
        e.preventDefault();
        switch (e.keyCode) {
          case 39: this.playNext(); break;  // Left arrow
          case 37: this.playPrev(); break;  // Right arrow
          case 32: this.pause(); break;     // Space
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
      "ncg": "ncg",
      "13percent": "thirteenPercent",
      "bpm": "bpm",
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

    ncg: function() {
      state.set({ location: 'New City Gas' });
    },

    thirteenPercent: function() {
      state.set({
        location: 'Le Salon Daomé',
        time: '2015-01-09T04:00:00.000Z'
      });
    },

    bpm: function() {
      state.set({ location: 'BPM' });
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
