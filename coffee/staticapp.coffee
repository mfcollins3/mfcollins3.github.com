###
Copyright 2015 Michael F. Collins, III
###

$(document).ready ->
  $('#example-app').submit (event) ->
    event.preventDefault()
    userData =
      firstName: $('#example-app input[name=firstName]').val()
      lastName: $('#example-app input[name=lastName]').val()
    $.ajax
      url: "https://michaelfcollins3.herokuapp.com/sayhello"
      type: "POST"
      data: JSON.stringify userData
      contentType: "application/json"
    .done (data) ->
      console.log data
      response = JSON.parse data
      $('#welcomeMessage').text response.greeting
      $('#welcomeMessage').parent().removeClass "hidden"
    .fail (xhr, status, err) ->
      console.log err
