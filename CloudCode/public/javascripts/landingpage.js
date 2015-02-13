
$(function() {

  Parse.$ = jQuery;

  Parse.initialize("gYVd0gSQavfnxcvIyFhns8j0KKyp0XHekKdrjJkC",
                   "ElJrtZZx480g2CrqVdJ7B6YPKRUBgIYGRzY5fMOa");


  var BetaSignup = Parse.Object.extend("BetaSignup");

  var SignUpView = Parse.View.extend({

    el: ".subscribe-form",

    template: _.template($("#signup-template").html()),

    events: {
      "submit form.signup-form": "signUp"
    },

    initialize: function() {
      _.bindAll(this, 'signUp');
      this.render();
    },

    signUp: function(e) {
      e.preventDefault();

      var self = this;
      var email = this.$("#signup-email").val().toLowerCase();

      if (email === "") {
        console.log("An email must be provided");
        return;
      }

      console.log("Email: " + email);
      var newSignup = new BetaSignup({email: email});;

      var promises = [];

      var queryExisting = new Parse.Query(BetaSignup);
      queryExisting.equalTo('email', email);
      promises.push(queryExisting.first());

      var referrerId = state.get('referrerId');

      if (referrerId) {
        var referrerId = new Parse.Query(BetaSignup);
        queryExisting.equalTo('objectId', referrerId);
        promises.push(referrerId.first());
      }

      Parse.Promise.when(promises).then(function(existingSignup, referrer) {
        if (existingSignup) {
          console.log(existingSignup.id + " already exists.");
        } else {
          if (referrer) {
            console.log("referrer: " + referrer.get('email'));
            newSignup.set({referrer: referrer});
          }

          return newSignup.save();
        }
      }).then(function(newSignup) {
        var message;
        if (newSignup) {
          console.log(newSignup.get('email') + " has signed up.");
          message = "Thanks for signing up! We'll get in touch soon."
        } else {
          message = "You're already on the list for early access."
        }
        this.$("div.slogan3").text(message);
        this.$("#signup-email").val("");
      }, function(error) {
        console.log("Error signing up for beta: " + error);
      });

    },

    render: function() {
      this.$el.html(this.template);
    },

  });

  var AppRouter = Parse.Router.extend({

    routes: {
      ':id': 'saveInvite'
    },

    saveInvite: function(id) {
      state.set({'referrerId': id});
    }
  })

  var AppState = Parse.Object.extend('AppState');
  var state = new AppState;

  new AppRouter;
  new SignUpView;

  Parse.history.start();
});
