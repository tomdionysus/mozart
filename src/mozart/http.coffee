{MztObject} = require './object'
Util = require './util'

# The HTTP class abstracts jQuery AJAX.
class HTTP extends MztObject

  # Handle an error status from the server
  # @param jqXHR [jQueryXHR] The jQuery XHR object
  # @param status [string] The jQuery status string
  # @param context [object] The jQuery event context
  # @param errorThrown [exception] The jQuery exception
  handleError: (jqXHR, status, context, errorThrown) ->
    switch jqXHR.status
      when 401
        Mozart.Ajax.publish('httpAuthorizationRequired',context, jqXHR)
      when 404
        Mozart.Ajax.publish('httpForbidden',context, jqXHR)
      else
        Util.error('Model.Ajax.handleError', jqXHR, status, errorThrown)

  # Prepare data for _request
  # @param url [string] The HTTP url
  # @param httpType [string] The HTTP verb
  # @param data [object] The data for the call
  # @param options [object] The options for the call
  # @param callbacks [object] A map of callback functions
  # @private
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

  # Make a jQuery AJAX call
  # Called by XHR Handler, can be overridden if you want to use another library or 
  # framework, defaults to jQuery with a JSON content type
  # @param url [string] The HTTP url
  # @param httpType [string] The HTTP verb
  # @param data [object] The data for the call
  # @param options [object] The options for the call
  # @param callbacks [object] A map of callback functions
  # @private
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

  # Support subobject
  support:
    ajax: ->
      try
        return !!(new XMLHttpRequest())
      catch error
        return false
    cors: ->
      @ajax and ("withCredentials" of new XMLHttpRequest())


  # Send a HTTP GET request
  # @param url [string] The HTTP url
  # @param arg [object] An object containing the data, options and callbacks for this request
  get: (url, arg) ->
    arg       = arg || {}
    data      = arg.data || {}
    options   = arg.options || {}
    callbacks = arg.callbacks || {}
    @_xhrHandler url, 'GET', data, options, callbacks
    
  # Send a HTTP POST request
  # @param url [string] The HTTP url
  # @param arg [object] An object containing the data, options and callbacks for this request
  post: (url, arg) ->
    arg       = arg || {}
    data      = arg.data || {}
    options   = arg.options || {}
    callbacks = arg.callbacks || {}
    @_xhrHandler url, 'POST', data, options, callbacks
    
  # Send a HTTP PUT request
  # @param url [string] The HTTP url
  # @param arg [object] An object containing the data, options and callbacks for this request
  put: (url, arg) ->
    arg       = arg || {}
    data      = arg.data || {}
    options   = arg.options || {}
    callbacks = arg.callbacks || {}
    @_xhrHandler url, 'PUT', data, options, callbacks
    

  # Send a HTTP DELETE request
  # @param url [string] The HTTP url
  # @param arg [object] An object containing the data, options and callbacks for this request
  delete: (url, arg) ->
    arg       = arg || {}
    data      = arg.data || {}
    options   = arg.options || {}
    callbacks = arg.callbacks || {}
    @_xhrHandler url, 'DELETE', data, options, callbacks

exports.HTTP = HTTP

