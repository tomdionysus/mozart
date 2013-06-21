{Model} = require './model'
Util = require './util'

_localStorageToClientId = {}
_clientToLocalStorageId = {}

Model.extend
# Model Extensions

  localStorage: (options) ->
    
    unless window.localStorage?
      Mozart.error @modelName+".localStorage - localStorage not available in this browser"

    options ?= {}
    options.prefix ?= "MozartLS"

    @localStorageOptions = options

    @bind 'load', @loadLocalStorage
    @bind 'create', @createLocalStorage
    @bind 'update', @updateLocalStorage
    @bind 'destroy', @destroyLocalStorage

    _localStorageToClientId[@modelName] ?= {}
    _clientToLocalStorageId[@modelName] ?= {}

    Mozart.LocalStorage ?= Mozart.MztObject.create
      handleError: (model, id, error) ->
        Mozart.LocalStorage.trigger('notFound', model, id, error)

    prefix = @getLocalStoragePrefix()
    
    @instanceClass.extend
      getLocalStorageId: ->
        @modelClass.getLocalStorageId(@id)

      existsInLocalStorage: ->
        localStorageId = @modelClass.getLocalStorageId(@id)
        window.localStorage[@+"-#{localStorageId}"]?

      loadLocalStorage: ->
        @modelClass.loadLocalStorage(@)

    # Setup PK
    localStorageId = window.localStorage[prefix+"-nextPK"]
    unless localStorageId?
      window.localStorage[prefix+"-nextPK"] = "1"
    
    # Setup Index
    idx = window.localStorage[prefix+"-index"]
    unless idx?
      window.localStorage[prefix+"-index"] = "[]"

  getLocalStoragePrefix: ->
    @localStorageOptions.prefix+"-"+@modelName

  registerLocalStorageId: (id,localStorageId) ->
    throw new Error "Model.registerLocalStorageId: #{@modelName} is not registered for localStorage." unless _localStorageToClientId[@modelName]?
    _localStorageToClientId[@modelName][localStorageId] = id
    _clientToLocalStorageId[@modelName][id] = localStorageId

  unRegisterLocalStorageId: (id,localStorageId) ->
    delete _localStorageToClientId[@modelName][localStorageId]
    delete _clientToLocalStorageId[@modelName][id]

  getLocalStorageId: (id) ->
    _clientToLocalStorageId[@modelName][id]

  getLocalStorageClientId: (localStorageId) ->
    _localStorageToClientId[@modelName][localStorageId]

  toLocalStorageObject: (instance) ->
    obj = {}
    for field, type of @attrs when field != 'id'
      obj[field] = instance[field]
    #Id
    obj.id = @getLocalStorageId(instance.id)
    #FKs
    for field, model of @fks
      obj[field] = model.getLocalStorageId(instance[field])
    #PolyFKs
    for field, typeField of @polyFks
      if instance[typeField]?
        obj[field] = Model.models[instance[typeField]].getLocalStorageId(instance[field])
      else 
        obj[field] = null
    obj

  toLocalStorageClientObject: (localStorageObject) ->
    obj = {}
    for field, type of @attrs when field != 'id'
      obj[field] = localStorageObject[field]
    #Id
    obj.id = @getLocalStorageClientId(localStorageObject.id)
    #FKs
    for field, model of @fks
      obj[field] = model.getLocalStorageClientId(localStorageObject[field])
      obj[field] = null if typeof(obj[field])=='undefined'
    #PolyFKs
    for field, typeField of @polyFks
      if localStorageObject[typeField]?
        obj[field] = Model.models[localStorageObject[typeField]].getLocalStorageClientId(localStorageObject[field])
      else 
        obj[field] = null
    obj

  loadAllLocalStorage: ->
    # get Index
    prefix = @getLocalStoragePrefix()

    idx = JSON.parse(window.localStorage[prefix+"-index"])

    for localStorageId in idx
      data = JSON.parse(window.localStorage[prefix+"-#{localStorageId}"])
      @_processLocalStorageLoad(localStorageId, data, @)

    @trigger('loadAllLocalStorageComplete')
    Util.log('localStorage','Model.loadAllLocalStorage.onComplete')

  loadLocalStorage: (instance) ->
    localStorageId = instance.modelClass.getLocalStorageId(instance.id)
    @loadLocalStorageId(localStorageId)

  loadLocalStorageId: (localStorageId) ->
    prefix = @getLocalStoragePrefix()

    data = window.localStorage[prefix+"-#{localStorageId}"]

    unless data?
      Mozart.LocalStorage.handleError(@,localStorageId,"record does not exist")

    data = JSON.parse(data)
    data.id = localStorageId

    @_processLocalStorageLoad(localStorageId,data,@)

  _processLocalStorageLoad: (localStorageId, data, model) ->
    clientId = model.getLocalStorageClientId(localStorageId)
    clientObject = model.toLocalStorageClientObject(data)
    if clientId?
      instance = model.findById(clientId)
      instance.copyFrom(clientObject)
    else
      instance = model.initInstance(data)
    instance.save
      disableModelCreateEvent: true
      disableModelUpdateEvent: true
    model.registerLocalStorageId(instance.id,localStorageId)
    Util.log('localStorage','Model._processLocalStorageLoad.onSuccess', data, model)
    model.trigger('loadLocalStorageComplete', instance)

  createLocalStorage: (instance) ->
    data = instance.modelClass.toLocalStorageObject(instance)
    prefix = instance.modelClass.getLocalStoragePrefix()

    # Get LS Next Free Primary Key
    localStorageId = parseInt(window.localStorage[prefix+"-nextPK"])
    window.localStorage[prefix+"-nextPK"] = (localStorageId+1).toString()

    # Save Record
    window.localStorage[prefix+"-#{localStorageId}"] = JSON.stringify(data)

    # Register LS pk with model
    instance.modelClass.registerLocalStorageId(instance.id,localStorageId)

    # Update LS Index
    idx = JSON.parse(window.localStorage[prefix+"-index"])
    idx.push(localStorageId)
    window.localStorage[prefix+"-index"] = JSON.stringify(idx)

    # Done
    Util.log('localStorage','Model.createLocalStorageComplete',instance)
    instance.modelClass.trigger('createLocalStorageComplete', instance)

  updateLocalStorage: (instance) ->
    localStorageId = instance.modelClass.getLocalStorageId(instance.id)
    return unless localStorageId?

    data = instance.modelClass.toLocalStorageObject(instance)
    prefix = instance.modelClass.getLocalStoragePrefix()

    # Check record exists in LS
    unless window.localStorage[prefix+"-#{localStorageId}"]?
      Mozart.LocalStorage.handleError(instance.modelClass,localStorageId,"updateLocalStorage: record does not exist")

    # Save Record
    window.localStorage[prefix+"-#{localStorageId}"] = JSON.stringify(data)

    # Done
    instance.modelClass.trigger('updateLocalStorageComplete', instance)
    Util.log('localStorage','Model.updateLocalStorage.onComplete', instance)

  destroyLocalStorage: (instance) ->
    localStorageId = instance.modelClass.getLocalStorageId(instance.id)
    return unless localStorageId?

    prefix = instance.modelClass.getLocalStoragePrefix()

    # Check record exists in LS
    unless window.localStorage[prefix+"-#{localStorageId}"]?
      Mozart.LocalStorage.handleError(instance.modelClass,localStorageId,"destroyLocalStorage: record does not exist")

    # Delete record
    window.localStorage.removeItem(prefix+"-#{localStorageId}")

    # Unregister with model
    instance.modelClass.unRegisterLocalStorageId(instance.id,localStorageId)

    # Update LS Index
    idx = JSON.parse(window.localStorage[prefix+"-index"])
    idx = _.without(idx,localStorageId)
    window.localStorage[prefix+"-index"] = JSON.stringify(idx)
    
    # Done
    Util.log('localStorage','Model.destroyLocalStorage.onSuccess',instance)
    instance.modelClass.trigger('destroyLocalStorageComplete', localStorageId)

  destroyAllLocalStorage: ->
    prefix = @getLocalStoragePrefix()
    idx = JSON.parse(window.localStorage[prefix+"-index"])

    for i in idx
      window.localStorage.removeItem(prefix+"-#{i}")

    window.localStorage[prefix+"-index"] = "[]"
    window.localStorage[prefix+"-nextPK"] = "1"

    _localStorageToClientId[@modelName] = {}
    _clientToLocalStorageId[@modelName] = {}
    
