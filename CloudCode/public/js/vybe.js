
$(function() {

  Parse.$ = jQuery;

  Parse.initialize("gYVd0gSQavfnxcvIyFhns8j0KKyp0XHekKdrjJkC",
                   "ElJrtZZx480g2CrqVdJ7B6YPKRUBgIYGRzY5fMOa");

  var video_player = document.getElementById("video_player"),
    video = video_player.getElementsByTagName("video")[0],
    source = video.getElementsByTagName("source"),
    playlist = document.getElementById("playlist"),
    video_links = playlist.children,
    link_list = [],
    path = 'media/',
    currentVid = 0;

  video.removeAttribute("controls");
  video.removeAttribute("poster");

  function playVid(index) {
    playlist.children[index].classList.add("currentvid");
    source[0].src = path + link_list[index] + ".mp4";
    currentVid = index;
    video.load();
    video.play();
  }

  for (var i=0; i<video_links.length; i++) {
    var filename = video_links[i].href;
    link_list[i] = filename.match(/([^\/]+)(?=\.\w+$)/)[0];

    (function(index){
      video_links[i].onclick = function(i){
        i.preventDefault();

        for (var i=0; i<video_links.length; i++) {
          video_links[i].classList.remove("currentvid");
        }

        playVid(index);
      }
    })(i);
  }

  video.addEventListener('ended', function () {
    var nextVid = currentVid + 1;

    if (nextVid >= video_links.length) {
      nextVid = 0;
    }

    video_links[currentVid].classList.remove("currentvid");
    playVid(nextVid);
  })

  video_links[0].click();
});
