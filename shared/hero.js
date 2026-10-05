/* Hero video control.
   ------------------------------------------------------------------
   The film autoplays muted and inline, as browsers allow. Three things
   can go wrong, and each needs a different outcome rather than a silent
   dead video frame:

   1. Autoplay is refused (data saver, low power, some mobile browsers).
      Show the poster, reveal the control as Play, and let the visitor start it.
   2. The visitor prefers reduced motion. Never autoplay; show the poster and
      offer Play. The poster is a real still of the studio, so the page is
      complete without a single frame of video.
   3. The <video> element or its source is unsupported. Hide the control
      entirely rather than offering a button that cannot work.

   The button is `hidden` in the markup on purpose: it should not exist at all
   until we know playback is possible.
*/
(function () {
  "use strict";

  var video = document.getElementById("hero-video");
  var toggle = document.getElementById("hero-toggle");
  if (!video || !toggle) return;

  var PLAY_LABEL = "Play the studio film";
  var PAUSE_LABEL = "Pause the studio film";
  var ICON_PLAY = '<path d="M8 5v14l11-7z"></path>';
  var ICON_PAUSE =
    '<rect x="6" y="5" width="4" height="14"></rect><rect x="14" y="5" width="4" height="14"></rect>';

  var reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)");

  function setIcon(playing) {
    toggle.querySelector("svg").innerHTML = playing ? ICON_PAUSE : ICON_PLAY;
    toggle.setAttribute("aria-label", playing ? PAUSE_LABEL : PLAY_LABEL);
    toggle.setAttribute("aria-pressed", playing ? "true" : "false");
  }

  function showToggle() {
    toggle.hidden = false;
  }

  // Nothing to control if the browser cannot play the file at all.
  function canPlay() {
    if (typeof video.canPlayType !== "function") return false;
    return (
      video.canPlayType('video/webm; codecs="vp9"') ||
      video.canPlayType('video/mp4; codecs="avc1.42E01E"') ||
      video.canPlayType("video/mp4")
    );
  }

  function tryPlay() {
    var attempt = video.play();
    if (attempt && typeof attempt.catch === "function") {
      attempt
        .then(function () {
          setIcon(true);
          showToggle();
        })
        .catch(function () {
          // Autoplay refused. The poster is already showing, so leave it and
          // offer the visitor a play button instead of an error.
          video.controls = false;
          setIcon(false);
          showToggle();
        });
    }
  }

  if (!canPlay()) {
    // Poster image alone carries the hero. Hide the video box so there is no
    // empty frame, and drop the control because it would do nothing.
    var media = video.parentNode;
    if (media) media.style.display = "none";
    return;
  }

  toggle.addEventListener("click", function () {
    if (video.paused) {
      var p = video.play();
      if (p && typeof p.catch === "function") p.then(function () { setIcon(true); });
      else setIcon(true);
    } else {
      video.pause();
      setIcon(false);
    }
  });

  video.addEventListener("play", function () { setIcon(true); });
  video.addEventListener("pause", function () { setIcon(false); });

  if (reduceMotion.matches) {
    // Do not move anything unless asked. Poster stays; Play appears.
    setIcon(false);
    showToggle();
    return;
  }

  tryPlay();

  // If the preference changes mid-session, respect it immediately.
  if (typeof reduceMotion.addEventListener === "function") {
    reduceMotion.addEventListener("change", function (e) {
      if (e.matches && !video.paused) {
        video.pause();
        setIcon(false);
        showToggle();
      }
    });
  }
})();