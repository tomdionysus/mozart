Util = require './util'

# Events is the core class for the Mozart event system. All Events in the system are 
# handled by this class, which should not be instantiated.
class Events
  # Callbacks contains the mapping for all events in the system
  @callbacks: {}

  # Initialises the event system for a specific MztObject and event
  # @param [string] objectId The MztObject id
  # @param [string] eventName The event name
  @eventInit: (objectId, eventName) ->
    Events.callbacks[objectId] ?= { count: 0, events: {} }
    Events.callbacks[objectId].events[eventName] ?= {}

  # Publishes the specified event eventName on the MztObject with objectId and data
  # @param [string] objectId The MztObject id
  # @param [string] eventName The event name
  # @param [object] data Data to be passed to the callback (optional)
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

  # Subscribe once to the specified event eventName on the MztObject with objectId
  # and remove the subscription after the first publication.
  # @param [string] objectId The MztObject id
  # @param [string] eventName The event name
  # @param [function] callback The callback function to be called when published
  # @param [object] binddata Data to be passed to the callback (optional)
  @subscribeOnce: (objectId, eventName, callback, binddata) ->
    Events.eventInit(objectId, eventName)
    Events.callbacks[objectId].events[eventName][Events.callbacks[objectId].count++] = { fn: callback, binddata: binddata, once: true }

  # Subscribe to the specified event eventName on the MztObject with objectId
  # @param [string] objectId The MztObject id
  # @param [string] eventName The event name
  # @param [function] callback The callback function to be called when published
  # @param [object] binddata Data to be passed to the callback (optional)
  @subscribe: (objectId, eventName, callback, binddata) ->
    Events.eventInit(objectId, eventName)
    Events.callbacks[objectId].events[eventName][Events.callbacks[objectId].count++] = { fn: callback, binddata: binddata }

  # Unsubscribe from a specified event on the MztObject with objectId and callback.
  # If the callback function is unspecified, unsubscribe all callbacks on that eventName
  # If both the eventName and the callback function are unspecified, unsubscribe from all events.
  # @param [string] objectId The MztObject id
  # @param [string] eventName The event name (optional)
  # @param [function] callback The callback function to be called when published (optional)
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

  # Get the subscriptions for the specified MztObject with objectId and eventName
  # @param [string] objectId The MztObject id
  # @param [string] eventName The event name
  # @return A list of binding objects
  @getSubscribed: (objectId, eventName) ->
    _(Events.callbacks[objectId].events[eventName]).values()

exports.Events = Events
