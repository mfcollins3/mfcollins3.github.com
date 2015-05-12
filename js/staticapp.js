
/*
Copyright 2015 Michael F. Collins, III
 */

(function() {
  $(document).ready(function() {
    return $('#example-app').submit(function(event) {
      var userData;
      event.preventDefault();
      userData = {
        firstName: $('#example-app input[name=firstName]').val(),
        lastName: $('#example-app input[name=lastName]').val()
      };
      return $.ajax({
        url: "https://michaelfcollins3.herokuapp.com/sayhello",
        type: "POST",
        data: JSON.stringify(userData),
        contentType: "application/json"
      }).done(function(data) {
        var response;
        console.log(data);
        response = JSON.parse(data);
        $('#welcomeMessage').text(response.greeting);
        return $('#welcomeMessage').parent().removeClass("hidden");
      }).fail(function(xhr, status, err) {
        return console.log(err);
      });
    });
  });

}).call(this);

//# sourceMappingURL=staticapp.js.map
