Util = require './util'

exports.Events = class Events
  @callbacks = {}

  @eventInit: (objectId, eventName) ->
    Events.callbacks[objectId] ?= { count: 0, events: {} }
    Events.callbacks[objectId].events[eventName] ?= {}

  @publish: (objectId, eventName, data) ->
    if Events.callbacks[objectId]? && Events.callbacks[objectId].events[eventName]?
      list = []
      for id, callbackFunction of Events.callbacks[objectId].events[eventName]
        Util.warn("general","Events: Error while publishing event '#{eventName}' on MztObject #{objectId}: call function does not exist ", callbackFunction.fn) unless callbackFunction.fn?
        try
          callbackFunction.fn.call(@, data, callbackFunction.binddata)
        catch ex
          Util.warn("Events: Error while publishing event '#{eventName}' on MztObject #{objectId}: call threw exception:",ex)
        list.push { objectId: objectId, eventName: eventName, id: id } if callbackFunction.once
      for callbackFunction in list
        delete Events.callbacks[callbackFunction.objectId].events[callbackFunction.eventName][callbackFunction.id]

  @subscribeOnce: (objectId, eventName, callback, binddata) ->
    Events.eventInit(objectId, eventName)
    Events.callbacks[objectId].events[eventName][Events.callbacks[objectId].count++] = { fn: callback, binddata: binddata, once: true }

  @subscribe: (objectId, eventName, callback, binddata) ->
    Events.eventInit(objectId, eventName)
    Events.callbacks[objectId].events[eventName][Events.callbacks[objectId].count++] = { fn: callback, binddata: binddata }

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

  @getSubscribed: (objectId, eventName) ->
    _(Events.callbacks[objectId].events[eventName]).values()
