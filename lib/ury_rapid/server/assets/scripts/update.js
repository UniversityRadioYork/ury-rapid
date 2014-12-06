/*
 * UPDATES CONSOLE
 */

// This will replace http with ws, but also https with wss, as intended.
// TODO(mattbw): Make this more elaborate, so that the updates console can go
// somewhere other than the inspector index.
var socketURL = (document.location.href.replace('http', 'ws')) + '/stream/';
var updateSocket = new WebSocket(socketURL);
updateSocket.onopen = function (event) {
  $('.updates #status').text('Socket opened.');
};
updateSocket.onmessage = function (event) {
  $('#update-console').append(event.data);
};
