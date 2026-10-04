/* Goose Fire — contact form
 *
 * WHY THIS IS NOT A PLAIN <form> POST:
 * There is no server here. This is a static site, and no mail or form provider is
 * configured. A plain form would either reload the page and lose the message, or
 * silently do nothing, which is the worst outcome for someone trying to reach us.
 *
 * So: validate properly, then hand the message to the visitor's own mail client
 * via a mailto: link. That works with no backend, no credentials, no third party
 * holding anyone's message, and no secret in the client code.
 *
 * WHAT THIS DELIBERATELY DOES NOT DO:
 *   - It does not claim the message was sent. Nothing was sent.
 *   - It does not show a fake success state.
 *   - It does not store anything, and it does not invent an email address.
 *
 * TO REPLACE THIS WITH A REAL FORM: point the form at a provider (see README),
 * delete this file's script, and update the note text. Keep the validation.
 */
(function () {
  "use strict";

  var form = document.getElementById("contact-form");
  if (!form) return;

  var note = document.getElementById("form-note");

  // Where messages go. Empty means: use the visitor's mail client instead.
  // Set this to your form endpoint (e.g. Formspree, Basin, a Cloudflare Worker)
  // when one exists, and the form will POST to it instead.
  var ENDPOINT = "";

  function setError(field, show) {
    var p = form.querySelector('.error[data-for="' + field.name + '"]');
    if (p) p.hidden = !show;
    field.setAttribute("aria-invalid", show ? "true" : "false");
  }

  function validate() {
    var name = form.elements.name;
    var email = form.elements.email;
    var message = form.elements.message;
    var ok = true;

    [name, email, message].forEach(function (f) { setError(f, false); });

    if (!name.value.trim()) { setError(name, true); ok = false; }
    // Deliberately loose: reject the obvious mistakes, accept everything else.
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(email.value.trim())) {
      setError(email, true);
      ok = false;
    }
    if (message.value.trim().length < 10) { setError(message, true); ok = false; }
    return ok;
  }

  form.addEventListener("submit", function (event) {
    event.preventDefault();
    note.className = "form-note";

    if (!validate()) {
      note.textContent = "Please check the highlighted fields.";
      var firstBad = form.querySelector('[aria-invalid="true"]');
      if (firstBad) firstBad.focus();
      return;
    }

    var name = form.elements.name.value.trim();
    var email = form.elements.email.value.trim();
    var message = form.elements.message.value.trim();

    if (ENDPOINT) {
      // A real endpoint: let the browser POST it. Server-side validation is the
      // provider's job; this is the client-side convenience layer only.
      form.setAttribute("action", ENDPOINT);
      form.setAttribute("method", "POST");
      return;
    }

    // No endpoint. Open the visitor's own mail client with the message filled in.
    // This is honest: the message is not sent by this site, it is handed to the
    // visitor's mail app, and the text below says exactly that.
    //
    // No "to" address is set, because we have not been given a verified one and
    // guessing an address would send mail nowhere while looking like it worked.
    var subject = "Goose Fire Ceramics, from " + name;
    var body = message + "\n\n---\n" + name + "\n" + email;
    window.location.href =
      "mailto:?subject=" + encodeURIComponent(subject) +
      "&body=" + encodeURIComponent(body);

    note.textContent =
      "Your email app should now be open with this message ready to send. " +
      "Nothing has been sent from this site, so it will not reach us until you press send.";
    note.className = "form-note form-note--info";
  });

  // Clear a field's error as soon as they fix it.
  ["name", "email", "message"].forEach(function (n) {
    var f = form.elements[n];
    if (!f) return;
    f.addEventListener("input", function () {
      if (f.getAttribute("aria-invalid") === "true") setError(f, false);
    });
  });
})();