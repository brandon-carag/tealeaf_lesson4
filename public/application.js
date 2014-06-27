//When the document is ready...
$(document).ready(function() {


//Attach yourself to the hit form
//traverse the DOM for #hit form input
//look for all the input attached to it.
//bind 

//Click is an event handler.  

  $(document).on('click', '#hit_form input',function() {

    $.ajax({
      type: 'POST',
      url: '/hit_me'
    }).done(function(msg) {
      $('#game').replaceWith(msg);
    });
 
//return false discontinues the execution of the button
    return false;
  });
});




// TO DO LIST
// Brush up on the CSS
// Traversing the DOM?
// console.log for Firefox

//what's going on?  We're using a function in HTML to AJAXify the request.

