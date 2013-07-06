Util = require './util'

exports.Events = class Events
  @callbacks = {}

  @eventInit: (objectId, eventName) ->
    Events.callbacks[objectId] ?= { count: 0, events: {} }
    Events.callbacks[objectId].events[eventName] ?= {}

  @trigger: (args...) -> @publish(args...)
  @publish: (objectId, eventName, data) ->
    if Events.callbacks[objectId]? && Events.callbacks[objectId].events[eventName]?
      list = []
      for id, callbackFunction of Events.callbacks[objectId].events[eventName]
        Util.log("general",'callback issue ', callbackFunction.fn) unless callbackFunction.fn.call?
        callbackFunction.fn.call(@, data, callbackFunction.binddata)
        list.push { objectId: objectId, eventName: eventName, id: id } if callbackFunction.once
      for callbackFunction in list
        delete Events.callbacks[callbackFunction.objectId].events[callbackFunction.eventName][callbackFunction.id]

  @one: (args...) -> @subscribeOnce(args...)
  @subscribeOnce: (objectId, eventName, callback, binddata) ->
    Events.eventInit(objectId, eventName)
    Events.callbacks[objectId].events[eventName][Events.callbacks[objectId].count++] = { fn: callback, binddata: binddata, once: true }

  @bind: (args...) -> @subscribe(args...)
  @subscribe: (objectId, eventName, callback, binddata) ->
    Events.eventInit(objectId, eventName)
    Events.callbacks[objectId].events[eventName][Events.callbacks[objectId].count++] = { fn: callback, binddata: binddata }

  @unbind: (args...) -> @unsubscribe(args...)
  @unsubscribe: (objectId, eventName, callback) ->
    if callback? && Events.callbacks[objectId]? && Events.callbacks[objectId].events[eventName]?
      list = []
      for id, callbackFunction of Events.callbacks[objectId].events[eventName]
        list.push id if callbackFunction.fn is callback 
      for id in list
        delete Events.callbacks[objectId].events[eventName][id]
      return

    if eventName? && Events.callbacks[objectId]? && Events.callbacks[objectId].events[eventName]?
      delete Events.callbacks[objectId].events[eventName]
      return

    delete Events.callbacks[objectId]

  @getBinds: (args...) -> @getSubscribed(args...)
  @getSubscribed: (objectId, eventName) ->
    _(Events.callbacks[objectId].events[eventName]).values()
