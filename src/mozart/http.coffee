# Mozart.HTTP
#
# - XHR abstraction layer

{MztObject} = require './object'
Util = require './util'

exports.HTTP = class HTTP extends MztObject

  #
  # ERROR HANDLER
  #
  
  handleError: (jqXHR, status, context, errorThrown) ->
    switch jqXHR.status
      when 401
        Mozart.Ajax.trigger('httpAuthorizationRequired',context, jqXHR)
      when 404
        Mozart.Ajax.trigger('httpForbidden',context, jqXHR)
      else
        Util.error('Model.Ajax.handleError', jqXHR, status, errorThrown)

  #
  # XHR HANDLER
  #
  
  _xhrHandler: (url, httpType, data, options, callbacks) ->
    if @support.ajax
    
      # Detect URL type, and look for CORS
      if typeof url == 'object'
        if @support.cors
          _url = url.cors or url.proxy
        else
          _url = url.proxy
      else
        _url = url

      _httpType = httpType || 'GET'
      _options = options || {}
      _callbacks = callbacks || {}
      _data = data || {}
    
      callbacks.success = callbacks.success || (data, jqXHR, status) ->
        Util.log('Mozart.HTTP', httpType, 'success', data, jqXHR, status)

      callbacks.error = callbacks.error || (jqXHR, status, errorThrown) ->
        Util.log('Mozart.HTTP', httpType, 'error', jqXHR, status, errorThrown)

      callbacks.complete = callbacks.complete || (jqXHR, status) ->
        Util.log('Mozart.HTTP', httpType, 'complete', jqXHR, status)
      
      @_request _url, _httpType, _data, _options, _callbacks

    else

      Util.log('Mozart.HTTP', 'AJAX is not supported. Exiting')

  #
  # REQUEST HANDLER
  # - Called by XHR Handler
  # - Can be overridden if you want to use another library or framework
  # - Defaults to jQuery with a JSON content type
  #
 
  _request: (url, httpType, data, options, callbacks) ->
    $.ajax
      url: url
      type: httpType
      success: callbacks.success
      error: callbacks.error
      complete: callbacks.complete
      data: data
      context: options.context || @
      dataType: options.dataType || 'json'
      contentType: options.contentType || 'application/json'

  #
  # HTTP SUPPORT
  #

  support:
    ajax: ->
      try
        return !!(new XMLHttpRequest())
      catch error
        return false
    cors: ->
      @ajax and ("withCredentials" of new XMLHttpRequest())


  #
  # HTTP GET
  #

  get: (url, arg) ->
    arg       = arg || {}
    data      = arg.data || {}
    options   = arg.options || {}
    callbacks = arg.callbacks || {}
    @_xhrHandler url, 'GET', data, options, callbacks
    
  #
  # HTTP POST
  #

  post: (url, arg) ->
    arg       = arg || {}
    data      = arg.data || {}
    options   = arg.options || {}
    callbacks = arg.callbacks || {}
    @_xhrHandler url, 'POST', data, options, callbacks
    
  #
  # HTTP PUT
  #

  put: (url, arg) ->
    arg       = arg || {}
    data      = arg.data || {}
    options   = arg.options || {}
    callbacks = arg.callbacks || {}
    @_xhrHandler url, 'PUT', data, options, callbacks
    

  #
  # HTTP DELETE
  #

  delete: (url, arg) ->
    arg       = arg || {}
    data      = arg.data || {}
    options   = arg.options || {}
    callbacks = arg.callbacks || {}
    @_xhrHandler url, 'DELETE', data, options, callbacks


