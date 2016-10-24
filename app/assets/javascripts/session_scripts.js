// Global SCAPE.message method
(function($, window, undefined){
  "use strict";

  var loggedIn, userName, wasLoggedIn, logIn, logOut, updateUserName, warning, alert, success;

  loggedIn = function() {
    return document.cookie.match(/; user_name=([^;]+)/) !== null
  }

  userName = function() {
    return document.cookie.match(/; user_name=([^;]+)/)[1]
  }

  updateUserName = function(user_name) {
    $('.user_name_placeholder').text(user_name);
  }

  logIn = function(user_name) {
    var user_name = userName();
    if (wasLoggedIn) {
      if (user_name !== wasLoggedIn) {
        updateUserName(user_name);
        warning('The logged in user has changed since this page was last viewed. You are now logged in as '+user_name+'.');
      }
    } else {
      updateUserName(user_name);
      $('body').addClass('logged_in').removeClass('logged_out');
      success('You were logged in as ' + user_name + ' in another tab.')
    }
    wasLoggedIn = user_name;
  }

  logOut = function(user_name) {
    var user_name = 'Guest'
    if (wasLoggedIn) {
      updateUserName(user_name);
      $('body').addClass('logged_out').removeClass('logged_in');
      wasLoggedIn = false;
      warning('An action in another tab or browser window has logged you out!');
    } else {
      // Nothing changed
      wasLoggedIn = false;
    }
  }

  success = function(message) {
    alert(message,'success','Notice!')
  }


  warning = function(message) {
    alert(message,'danger','Warning!')
  }


  alert = function(message,category,title_text) {
    var newDiv = document.createElement("div");
    var title = document.createElement("strong");
    title.appendChild(document.createTextNode(title_text+' '));
    newDiv.appendChild(title);
    newDiv.appendChild(document.createTextNode(message));
    newDiv.setAttribute('class','alert alert-'+category)
    document.getElementById('flashes').appendChild(newDiv)
  }




  wasLoggedIn = loggedIn() && userName();

  $(window).on('focus',function() {
    loggedIn() ? logIn() : logOut();
  })

})(jQuery,window);
