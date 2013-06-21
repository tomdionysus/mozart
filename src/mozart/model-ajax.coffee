{Model} = require './model'
Util = require './util'

_serverToClientId = {}
_clientToServerId = {}

Model.extend
  
  #
  # AJAX
  #
  
  ajax: (options) ->
    for field in ['url','interface','plural']
      @[field] = options[field] if options[field]?

    @bind 'load', @loadServer
    @bind 'create', @createServer
    @bind 'update', @updateServer
    @bind 'destroy', @destroyServer

    _serverToClientId[@modelName] ?= {}
    _clientToServerId[@modelName] ?= {}

    Mozart.Ajax ?= Mozart.MztObject.create
      handleError: (jqXHR, status, context, errorThrown) ->
        switch jqXHR.status
          when 401
            Mozart.Ajax.trigger('httpAuthorizationRequired',context, jqXHR)
          when 404
            Mozart.Ajax.trigger('httpForbidden',context, jqXHR)
          else
            Util.error('Model.Ajax.handleError', jqXHR, status, errorThrown)

    @instanceClass.extend
      getServerId: ->
        @modelClass.getServerId(@id)

      existsOnServer: ->
        @modelClass.getServerId(@id)?

      loadServer: ->
        @modelClass.load(@modelClass.getServerId(@id))

  #
  # Register Server ID
  #
  
  registerServerId: (id,serverId) ->
    throw new Error "Model.registerServerId: #{@modelName} is not registered for ajax." unless _serverToClientId[@modelName]?
    _serverToClientId[@modelName][serverId] = id
    _clientToServerId[@modelName][id] = serverId

  #
  # Unregister Server ID
  #
  
  unRegisterServerId: (id,serverId) ->
    delete _serverToClientId[@modelName][serverId]
    delete _clientToServerId[@modelName][id]

  #
  # GET SERVER ID
  #
  
  getServerId: (id) ->
    _clientToServerId[@modelName][id]

  #
  # GET CLIENT ID
  #
  
  getClientId: (serverId) ->
    _serverToClientId[@modelName][serverId]

  #
  # TO SERVER OBJECT
  #
  
  toServerObject: (instance) ->
    obj = {}
    for field, type of @attrs when field != 'id'
      obj[field] = instance[field]
    #Id
    obj.id = @getServerId(instance.id)
    #FKs
    for field, model of @fks
      obj[field] = model.getServerId(instance[field])
    #PolyFKs
    for field, typeField of @polyFks
      if instance[typeField]?
        obj[field] = Model.models[instance[typeField]].getServerId(instance[field])
      else 
        obj[field] = null
    obj

  #
  # TO CLIENT OBJECT
  #
  
  toClientObject: (serverObject) ->
    obj = {}
    for field, type of @attrs when field != 'id'
      obj[field] = serverObject[field] if typeof(serverObject[field]) != 'undefined'
    #Id
    obj.id = @getClientId(serverObject.id)
    #FKs
    for field, model of @fks
      if typeof(serverObject[field]) != 'undefined'
        obj[field] = model.getClientId(serverObject[field])
        obj[field] = null if typeof(obj[field])=='undefined'
    #PolyFKs
    for field, typeField of @polyFks
      if typeof(serverObject[field]) != 'undefined' and serverObject[typeField]?
        obj[field] = Model.models[serverObject[typeField]].getClientId(serverObject[field])
      else 
        obj[field] = null
    obj

  #
  # LOAD SERVER
  #
  
  loadServer: (instance) ->
    serverId = instance.modelClass.getServerId(instance.id)
    return unless serverId?
    instance.modelClass.load(serverId)

  #
  # CREATE SERVER
  #
  
  createServer: (instance) ->
    instance.modelClass.createAjax(instance.id,instance.modelClass.toServerObject(instance))

  #
  # UPDATE SERVER
  #
  
  updateServer: (instance) ->
    serverId = instance.modelClass.getServerId(instance.id)
    return unless serverId?
    instance.modelClass.updateAjax(serverId,instance.id,instance.modelClass.toServerObject(instance))

  #
  # DESTROY SERVER
  #
  
  destroyServer: (instance) ->
    serverId = instance.modelClass.getServerId(instance.id)
    return unless serverId?
    instance.modelClass.destroyAjax(instance.modelClass.getServerId(instance.id),instance.id)

  #
  # LOAD ALL
  #
  
  loadAll: ->
    onSuccess = (data, jqXHR, status) ->
      if @model.plural? #TODO: Should defer to interfaces module
        data = data[@model.plural]
      for obj in data
        @model._processLoad(obj,@model,jqXHR)
      @model.trigger('loadAllComplete')

    onError = (jqXHR, status, errorThrown) ->
      Mozart.Ajax.handleError(jqXHR, status, @, errorThrown)

    onComplete = (jqXHR, status) ->
      Util.log('ajax','Model.loadAll.onComplete', jqXHR, status)

    HTTP = Mozart.HTTP.create()
    HTTP.get(@url, { options: {context: {model: @}}, callbacks: {success: onSuccess, error: onError, complete: onComplete} })

  #
  # LOAD
  #
  
  load: (serverId) ->
    onSuccess = (data, jqXHR, status) ->
      if @model.plural? #TODO: Should defer to interfaces module
        data = data[@model.plural]
      @model._processLoad(data,@model,jqXHR)

    onError = (jqXHR, status, errorThrown) ->
      Mozart.Ajax.handleError(jqXHR, status, @, errorThrown)

    onComplete = (jqXHR, status) ->
      Util.log('ajax','Model.load.onComplete', jqXHR, status)

    HTTP = Mozart.HTTP.create()
    HTTP.get(@url+"/"+serverId, { options: {context: {model: @, id:serverId}}, callbacks: {success: onSuccess, error: onError, complete: onComplete} })

  #
  # PROCESS LOAD
  #
  
  _processLoad: (data,model,jqXHR) ->
    serverId = data.id
    clientObject = model.toClientObject(data)
    instance = model.findById(clientObject.id)
    unless instance?
      instance = model.initInstance(data)
    model.registerServerId(instance.id,serverId)
    instance.copyFrom(clientObject)
    instance.save
      disableModelCreateEvent: true
      disableModelUpdateEvent: true
    Util.log('ajax','Model._processLoad.onSuccess',jqXHR, data)
    model.trigger('loadComplete', instance)

  #
  # CREATE AJAX
  #
  
  createAjax: (clientId, data) ->
    onSuccess = (data, jqXHR, status) ->
      @model.registerServerId(@clientId,data.id)
      Util.log('ajax','Model.createAjax.onSuccess',jqXHR, data)
      @model.trigger('createComplete', @model.findById(clientId))

    onError = (jqXHR, status, errorThrown) ->
      Mozart.Ajax.handleError(jqXHR, status, @, errorThrown)

    onComplete = (jqXHR, status) ->
      Util.log('ajax','Model.createAjax.onComplete', jqXHR, status)
    
    HTTP = Mozart.HTTP.create()
    HTTP.post(@url, {data: JSON.stringify(data), options: {context: {model: @, clientId:clientId}}, callbacks: {success: onSuccess, error: onError, complete: onComplete} })

  #
  # UPDATE AJAX
  #
  
  updateAjax: (serverId, clientId, data) ->
    onSuccess = (data, jqXHR, status) ->
      Util.log('ajax','Model.updateAjax.onSuccess',jqXHR, data)
      @model.trigger('updateComplete', @model.findById(clientId))

    onError = (jqXHR, status, errorThrown) ->
      Mozart.Ajax.handleError(jqXHR, status, @, errorThrown)

    onComplete = (jqXHR, status) ->
      Util.log('ajax','Model.updateAjax.onComplete', jqXHR, status)
    
    HTTP = Mozart.HTTP.create()
    HTTP.put(@url+'/'+serverId, {data: JSON.stringify(data), options: {context: {model: @, clientId:@clientId, serverId:@serverId}}, callbacks: {success: onSuccess, error: onError, complete: onComplete} })

  #
  # DESTROY AJAX
  #
  
  destroyAjax: (serverId, clientId) ->
    onSuccess = (data, jqXHR, status) ->
      @model.unRegisterServerId(clientId,serverId)
      Util.log('ajax','Model.destroyAjax.onSuccess',jqXHR, data)
      @model.trigger('destroyComplete', serverId)

    onError = (jqXHR, status, errorThrown) ->
      Mozart.Ajax.handleError(jqXHR, status, @, errorThrown)

    onComplete = (jqXHR, status) ->
      Util.log('ajax','Model.destroyAjax.onComplete', jqXHR, status)

    HTTP = Mozart.HTTP.create()
    HTTP.delete(@url+'/'+serverId, { options: {context: {model: @, clientId:clientId, serverId:serverId}}, callbacks: {success: onSuccess, error: onError, complete: onComplete} })

