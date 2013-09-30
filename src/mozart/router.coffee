{MztObject} = require './object'
Util = require './util'

# Router is the base class for Mozart classes capable of responding to routes.
#
# The router has two modes, specified by the useHashRouting property:
# * Popstate Routing (default)
# * Hash routing 
class Router extends MztObject

  # Initialise the Router
  init: =>
    @routes = {}
    @useHashRouting ?= false

  # Start responding to route changes on either popstate or hash changes, depending
  # on the value of useHashRouting.
  start: =>
    if (@useHashRouting)
      $(window).on('hashchange', @onHashChange)
      @onHashChange()
    else
      $('body').on("click", 'a', @onNavigationEvent)
      $(window).on("popstate", @onPopState)
      @onPopState()

  # Stop responding to route changes.
  stop: =>
    if (@useHashRouting)
      $(window).off('hashchange',@onHashChange)
    else
      $('body').off("click", 'a', @onNavigationEvent)
      $(window).off("popstate", @onPopState)

  # Register a route with the specified parameters
  # @param [string] route The route URL fragment, which can include parameters ('/route/:parameter')
  # @param [function] callback The callback function to call when the route is triggered
  # @param [object] data (optional) Data to pass to the callback function
  register: (route, callback, data) =>
    Util.log('routes',"registering route", route, data)
    tokens = route.split('/')
    params = []
    regex = ''
    for token in tokens
      if token[0] == ':'
        regex += '([^\\/]+)\\/'
        params.push(token.substr(1))
      else
        regex += @_escForRegEx(token)+'\\/'
    regex = regex.substr(0, regex.length-2) if regex.length>2 
    @routes[route] =
      regex: new RegExp('^'+regex+'$','i')
      params: params
      callback: callback
      data: data

  # When in Hash routing mode, this is called on the onHashChange window event.
  # Parse the hash route and navigate to it.
  onHashChange: =>
    url = window.location.hash
    url = url.substr(1) if url.length>0 and url[0]=='#'
    @navigateRoute(url)

  # When in popstate routing mode (the default), this is called on click events
  # on anchor (<a>) elements in the DOM. Detect if this is a route on our domain,
  # port and protocol, and navigate to it if we handle that route.
  # @param [DOMEvent] event The DOM event object
  onNavigationEvent: (event) =>
    # Return if route not on us.
    return if event.target.host!=document.location.host or
      event.target.port!=document.location.port or
      event.target.protocol!=document.location.protocol

    if @navigateRoute(event.target.pathname)
      history.pushState({one:1},null,event.target.href)
      event.preventDefault()

  # When in popstate routing mode (the default), this is called on the popstate 
  # window event. Parse the url route and navigate to it.
  onPopState: =>
    @navigateRoute window.location.pathname
    
  # Navigate to the specified urlPath if there is a registered route that matches it.
  # Publish the noroute event if the route is not found.
  # @param [string] urlPath The URL path of the route to navigate to.
  navigateRoute: (urlPath) =>
    @isNavigating = true

    if !urlPath? or urlPath.length == 0
      route = @routes['/']
      if route?
        route.callback(route.data, obj)
        @isNavigating = false
        return false
      else
        Util.log("routemanager", "WARNING: No Default route defined, no route for path",urlPath)

    for path, route of @routes
      obj = {}
      m = route.regex.exec(urlPath)
      if m != null
        i = 1
        for pn in route.params
          obj[pn] = m[i++] if i < m.length
        route.callback(route.data, obj)
        @isNavigating = false
        return true

    @isNavigating = false
    @publish('noroute',window.location.hash)
    false

  # Release this Router, stopping listening to routing events.
  release: =>
    @stop()
    super

  # Escape a string to be used in a regular expression.
  # @param [string] str The string to escape
  # @return [string] The escaped string
  # @private
  _escForRegEx: (str) ->
    str.replace('\\','\\\\')
    escchars = "./+{}()*"
    for i in escchars
      str = str.replace(i,'\\'+i)
    str

exports.Router = Router

