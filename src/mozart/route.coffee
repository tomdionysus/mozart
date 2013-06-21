Util = require './util'
{MztObject} = require './object'

exports.Route = class Route extends MztObject

  init: ->
    Util.warn 'Route must have a path', @ unless @path? and @path.length > 0
    Util.warn 'Route must have a viewClass', @ unless @viewClass?

  canExit: =>
    !@exit? or @exit() == true

  canEnter: (params) =>
    !@enter? or @enter(params) == true

  doTitle: =>
    if @title?
      if typeof(@title) == 'function'
        document.title = @title(@) 
      else
        document.title = @title