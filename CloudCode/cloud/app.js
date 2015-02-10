var express = require('express');
var app = express();

app.set('views', 'cloud/views');
app.set('view engine', 'ejs');

app.get('/', function(req, res) {
	res.render('landingpage.ejs');
});

app.get('/refer-a-friend', function(req, res) {
});

app.get('/player', function(req, res) {
	res.render('player.ejs');
});

app.post('/users/create', function(req, res) {
});

app.listen();
