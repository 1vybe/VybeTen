var express = require('express');
var app = express();

app.get('/player', function(req, res) {
    res.redirect(301, '/player.html');
});

app.listen();
