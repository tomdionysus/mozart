Util = require './util'

exports.Events = class Events
  @callbacks = {}

  @eventInit: (objectId, eventName) ->
		# TODO? Should these be setting the static Events.callbacks or eventsInstance.callbacks?
    Events.callbacks[objectId] ?= { count: 0, events: {} }
    Events.callbacks[objectId].events[eventName] ?= {}

  @trigger: (objectId, eventName, data) ->
    if Events.callbacks[objectId]? && Events.callbacks[objectId].events[eventName]?
      list = []
      for id, callbackFunction of Events.callbacks[objectId].events[eventName]
        Util.log("general",'callback issue ', callbackFunction.fn) unless callbackFunction.fn.call?
        callbackFunction.fn.call(@, data, callbackFunction.binddata)
        list.push { objectId: objectId, eventName: eventName, id: id } if callbackFunction.once
      for callbackFunction in list
        delete Events.callbacks[callbackFunction.objectId].events[callbackFunction.eventName][callbackFunction.id]

  @one: (objectId, eventName, callback, binddata) ->
    Events.eventInit(objectId, eventName)
    Events.callbacks[objectId].events[eventName][Events.callbacks[objectId].count++] = { fn: callback, binddata: binddata, once: true }

  @bind: (objectId, eventName, callback, binddata) ->
    Events.eventInit(objectId, eventName)
    Events.callbacks[objectId].events[eventName][Events.callbacks[objectId].count++] = { fn: callback, binddata: binddata }

  @unbind: (objectId, eventName, callback) ->
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

  @getBinds: (objectId, eventName) ->
    _(Events.callbacks[objectId].events[eventName]).values()
