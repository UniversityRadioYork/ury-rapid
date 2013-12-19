/* JavaScript for the BRA API Inspector. */

/*
 * TOOLBAR
 */

$( 'header' ).append(
  ( '<nav id="toolbar">'
  + '  <h1>Send Requests</h1>'
  + '  <label for="toolbar-data">Payload (JSON)</label>'
  + '  <input type="text" id="toolbar-data">'
  + '  <a class="toolbar-button" id="toolbar-put">Put</a>'
  + '  <a class="toolbar-button" id="toolbar-post">Post</a>'
  + '  <a class="toolbar-button" id="toolbar-delete">Delete</a>'
  + '</nav>'
  )
);


$( '#toolbar-put' ).click(function() { toolbar_do('PUT'); });
$( '#toolbar-post' ).click(function() { toolbar_do('POST'); });
$( '#toolbar-delete' ).click(function() { toolbar_do('DELETE'); });

/* Perform a toolbar command.
 *
 * This uses the data stored in #toolbar-data.
 *
 * Args:
 *   action - The action (one of 'PUT', 'POST' and 'DELETE' to perform.
 */
function toolbar_do(action)
{
  var request = $.ajax(
    { type: action
    , url: $( location ).attr('href')
    , data: $( '#toolbar-data' ).val()
    , processData: false
    , contentType: 'application/json'
    }
  );
  request.done(
    function( msg ) {
      location.reload();
    }
  );
  request.fail(
    function( jqXHR, msg ) {
      alert(action + ' failed: ' + jqXHR.responseText);
    }
  );
}
