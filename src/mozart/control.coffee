{View} = require './view'

exports.Control = class Control extends View
  idPrefix: 'control'

  error: (help) ->
    @help = help
    @errorState = true
    
  afterRender: =>
    if @errorState
      @element.addClass('error')
