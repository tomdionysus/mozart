Util = require './util'
{MztObject} = require './object'

# Route is the base class for Mozart Routes, used in layouts.
#
# Routes have a path, a viewClass and optionally a window title and enter and exit methods.
# Path is of the format '/path' and represents the routable URL. Paths can have parameters
# in the format '/person/:name', which will be parsed and supplied to the enter method.
class Route extends MztObject

  # Init checks that path and viewClass exist and warns otherwise.
  init: ->
    Util.warn 'Route must have a path', @ unless @path? and @path.length > 0
    Util.warn 'Route must have a viewClass', @ unless @viewClass?

  # Check if the route can exit by calling its exit method.
  # @return [boolean] Returns true if the route can exit.
  canExit: =>
    @exit() == true

  # Check if the route can enter by calling its enter method.
  # @param [object] A map of the route path parameters.
  # @return [boolean] Returns true if the route can enter.
  canEnter: (params) =>
    @enter(params) == true

  # Set the window title with this route if one is defined.
  doTitle: =>
    if @title?
      if typeof(@title) == 'function'
        document.title = @title(@) 
      else
        document.title = @title

  # exit should be overridden with teardown code for the route. It should return true to
  # transition to the next route, or false to cancel the route exit and stay on the current route.
  exit: ->
    true

  # enter should be overridden with setup code for the route. It should return true to allow
  # the route transition, or false to cancel and stay on the previous route.
  # @param args [object] A map of path parameters from the route.
  enter: (args) ->
    true

exports.Route = Route