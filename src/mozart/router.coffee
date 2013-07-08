{MztObject} = require './object'
Util = require './util'

exports.Router = class Router extends MztObject

  init: =>
    @routes = {}
    @useHashRouting ?= false

  start: =>
    if (@useHashRouting)
      $(window).on('hashchange', @onHashChange)
      @onHashChange()
    else
      $('body').on("click", 'a', @onNavigationEvent)
      $(window).on("popstate", @onPopState)
      @onPopState()

  stop: =>
    if (@useHashRouting)
      $(window).off('hashchange',@onHashChange)
    else
      $('body').off("click", 'a', @onNavigationEvent)
      $(window).off("popstate", @onPopState)

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

  onHashChange: =>
    url = window.location.hash
    url = url.substr(1) if url.length>0 and url[0]=='#'
    @navigateRoute(url)

  onNavigationEvent: (event) =>
    # Return if route not on us.
    return if event.target.host!=document.location.host or
      event.target.port!=document.location.port or
      event.target.protocol!=document.location.protocol

    if @navigateRoute(event.target.pathname)
      history.pushState({one:1},null,event.target.href)
      event.preventDefault()

  onPopState: =>
    @navigateRoute window.location.pathname
    
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

  release: =>
    @stop()
    super

  _escForRegEx: (str) ->
    str.replace('\\','\\\\')
    escchars = "./+{}()*"
    for i in escchars
      str = str.replace(i,'\\'+i)
    str

