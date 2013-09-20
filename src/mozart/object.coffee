Util = require './util'
{Events} = require './events'

# MztObject is the base class for all Mozart classes. It provides the core event,
# mixin and data binding functionality.
#
# MztObject and all descendant classes should be instantiated with the create method 
# on the class, to allow the binding system to be set up correctly.
# In descendant classes, you should implement the init() method as a constructor,
# which will ensure all bindings are available for use by your constructor.
#
# Any property on a MztObject can be bound to any property on another MztObject. 
# Bindings come in three types, SYNC, OBSERVE and NOTIFY (bidirectional, observe only, 
# and notify only) and can be created declaratively by adding properties to the MztObject
# before instantiation (pass a map of properties/values to create()) with the following
# suffixes:
# * ObserveBinding  (Observe - read only)
# * NotifyBinding (Notify - write only)
# * Binding (Sync - bidirectional)
#
# For more information, please see http://www.mozart.io/guides/understanding_binding
#
# All MztObjects support events in a pub/sub manner, using subscribe(), subscribeOnce(),
# publish() and unsubscribe().
#
# In addition, all MztObjects publish an event 'change:*propertyName*' when a property is
# set(), where propertyName is the name of the property that has been set.
#
class MztObject
  # Class Constants
  @NOTIFY: 2
  @OBSERVE: 1
  @SYNC: 0

  # Include the supplied object, that is, copy all of its properties and methods onto this object.
  # @param [object] obj Include all properties and functions from the supplied object on all instances of this class
  # @return [class] Returns this class
  @include: (obj) ->
    @[key] = value for key, value of obj

  # Extend this class with supplied object that is, copy all of its properties and methods onto this class.
  # @param [object] obj Include all properties and functions from the supplied object on the prototype of this class
  # @return [class] Returns this class
  @extend: (obj) ->
    @::[key] = value for key, value of obj

  # Create an instance of this object with the supplied attributes, set up its bindings and call its init method.
  # @param [object] options An object of properties and functions to initialize the object with.
  # @return [MztObject] Returns the new instance.
  @create: (options) ->
    inst = new this()

    inst[k] = v for k, v of options

    inst._bindings = {}
    inst._bindings.notify = {}
    inst._bindings.observe = {}
    inst._bindings.stored = {}
   
    inst._createDeclaredBinds()
    inst._createLookups()

    inst.init?()
    inst

  # Instantiate an instance of this class. Never use JavaScript ```new``` directly with MztObject or its descendants,
  # please call the [create] method. MztObjects instantiated using JS/CS ```new``` will not have bindings, lookups and events
  # correctly initialized. Please use the [create] method on the class instead.
  constructor: ->
    @_mozartId = Util.getId()

  # Return a string identifier for this instance
  toString: ->
    "obj-#{@_mozartId}"

  # Get the value of the supplied attribute on this object. If the attribute is a function, call it and return the value.
  # @param [string] key The name of the attribute to get.
  # @return [variant] The value of the attribute, or return value of the function.
  get: (key) ->
    if Util.isFunction(@[key])
      @[key].call(@)
    else
      @[key]

  # Set the value of the supplied attribute on this object and update all associated bindings. If the attribute is a function, call it with the supplied value as a single parameter.
  # @param [string] key The name of the attribute to set.
  # @param [variant] value The value to set.
  set: (key, value) ->
    oldValue = @[key]

    if oldValue isnt value
      # Binding Transfer: This deserves some explanation. 
      # Take a look at the 'Bindings on targets that change' spec in object-spec.coffee
      # Essentially for this to work, when a property is set, if the old value is an
      # MztObject then we need to strip all bindings from it and store them on *this* 
      # object. If the new value is also a MztObject, we need to apply those stored
      # bindings to the new object.

      if oldValue instanceof Mozart.MztObject
        @_bindings.stored[key] = {
          notify: oldValue._stripNotifyBindings(true)
          observe: oldValue._stripObserveBindings(true)
        }
        if @_bindings.stored[key].notify == {} and @_bindings.stored[key].observe == {}
          delete @_bindings.stored[key] 

      # If the new value is explicitly null, and there are stored bindings for this
      # property, we should iterate them and set all targets to null. This means 
      # where a binding 'a' is on 'x.y' and 'x' is now null, a should be set to null.
      if @_bindings.stored[key]? and @_bindings.stored[key].notify? and value == null
        for nv, bindings of @_bindings.stored[key].notify
          for binding in bindings
            binding.target.set(binding.attr, null)

      if value instanceof Mozart.MztObject and @_bindings.stored[key]?
        value._addNotifyBindings(@_bindings.stored[key].notify) unless @_bindings.stored[key].notify == {}
        value._addObserveBindings(@_bindings.stored[key].observe) unless @_bindings.stored[key].observe == {}
        delete @_bindings.stored[key]

      @[key] = value

      @_doNotifyBinding(key)
      @publish('change')
      @publish('change:'+key)

  # Subscribe to an event with the supplied name and callback
  # @param [string] event The name of the event
  # @param [function] callback The callback function 
  subscribe: (args...) ->
    Events.subscribe(@_mozartId, args...)
    @

  # Subscribe to an event with the supplied name and callback once only - remove the subscription after the first time the event is raised.
  # @param [string] event The name of the event
  # @param [function] callback The callback function 
  subscribeOnce: (args...) ->
    Events.subscribeOnce(@_mozartId, args...)
    @

  # Publish an event with the supplied name and data
  # @param [string] event The name of the event
  # @param [variant] data The data passed to the callback functions
  publish: (args...) ->
    Events.publish(@_mozartId, args...)
    @

  # Unsubscribe from an event with the supplied name and callback.
  #   If callback is ommited, unsubscribe the object from all events of this name.
  #   If callback and event are ommited, unsubscribe the object all events on all objects.
  # @param [string] event The name of the event
  # @param [function] callback The callback function 
  unsubscribe: (args...) ->
    Events.unsubscribe(@_mozartId, args...)
    @

  # Release this class instance, tearing down all data and unsubscribing from all events.
  release: ->
    return if @released
    @_removeAllBindings()
    @unsubscribe()
    for own k,v of @
      @[k] = undefined
      delete @[k]
    @released = true

  # Strip and Return Notify bindings from the instance
  # @param [boolean] transferOnly Strip and return only transferrable notify bindings if true.
  # @return [object] Return a map of bindings by attribute.
  # @private
  _stripNotifyBindings: (transferOnly = false) ->
    bindings = {}
    for key, cbindings of @_bindings.notify
      bindings[key] = []
      for binding in cbindings when (!transferOnly or binding.transferable)
        bindings[key].push binding
        @_removeBinding(key, binding.target, binding.attr, MztObject.NOTIFY)
    bindings

  # Add a map of notify bindings to this object
  # @param [object] bindingset A map of notify bindings to add to this instance. 
  # @private
  _addNotifyBindings: (bindingset) ->
    for key, bindings of bindingset
      for binding in bindings
        @_createBinding(key, binding.target, binding.attr, MztObject.NOTIFY, binding.transferable)

  # Strip and Return Observe bindings from the instance
  # @param [boolean] transferOnly Strip and return only transferrable observe bindings if true.
  # @return [object] Return a map of bindings by attribute.
  # @private
  _stripObserveBindings: (transferOnly = false)  ->
    bindings = {}
    for key, cbindings of @_bindings.observe
      bindings[key] = []
      for binding in cbindings when (!transferOnly or binding.transferable)
        bindings[key].push binding
        @_removeBinding(key, binding.target, binding.attr, MztObject.OBSERVE)
    bindings

  # Add a map of observe bindings to this instance
  # @param [object] bindingset A map of observe bindings to add to this instance. 
  # @private
  _addObserveBindings: (bindingset) ->
    for key, bindings of bindingset
      for binding in bindings
        @_createBinding(key, binding.target, binding.attr, MztObject.OBSERVE, binding.transferable)

  # Create declarative bindings from attributes of this instance ending in Binding, ObserveBinding or NotifyBinding
  # @private
  _createDeclaredBinds: ->
    for key, v of @ when !Util.isFunction(@[key]) and Util.stringEndsWith(key, "Binding")
      key = Util.sliceStringBefore(key, "Binding")
      type = MztObject.SYNC
      if Util.stringEndsWith(key, 'Observe')
        key = Util.sliceStringBefore(key, "Observe")
        type = MztObject.OBSERVE
      else if Util.stringEndsWith(key, 'Notify')
        key = Util.sliceStringBefore(key, "Notify")
        type = MztObject.NOTIFY

      [path, attr] = Util.parsePath(v)
      if path?
        obj = Util._getPath(@,path)
      else
        obj = @

      @_createBinding(key, obj, attr, type, Util.isAbsolutePath(v))

  # Check if this instance has the specified notify binding
  # @param [string] property The property on this instance that is notifying
  # @param [MztObject] target The target MztObject 
  # @param [string] targetProperty The property on the target that is observing
  # @return [boolean] Return true if the binding exists. 
  # @private
  _hasNotifyBinding: (property, target, targetProperty) ->
    return false unless @_bindings.notify[property]?
    for binding in @_bindings.notify[property]
      return true if binding.attr==targetProperty and binding.target._mozartId==target._mozartId
    return false

  # Check if this instance has the specified observe binding
  # @param [string] property The property on this instance that is observing
  # @param [MztObject] target The target MztObject 
  # @param [string] targetProperty The property on the target that is notifying
  # @return [boolean] Return true if the binding exists.   
  # @private
  _hasObserveBinding: (property, target, targetProperty) ->
    return false unless @_bindings.observe[property]?
    for binding in @_bindings.observe[property]
      return true if binding.attr==targetProperty and binding.target._mozartId==target._mozartId
    return false

  # Create the specified binding on this instance
  # @param [string] property The property on this instance that is observing
  # @param [MztObject] target The target MztObject 
  # @param [string] targetProperty The property on the target that is notifying
  # @param [constant] The type of the binding [ MztObject.NOTIFY, MztObject.OBSERVE, MztObject.SYNC ]
  # @param [boolean] transferable True if the binding is transferrable
  # @private
  _createBinding: (property, target, targetProperty, type, transferable) ->
    switch type
      
      when MztObject.NOTIFY
        return if @_hasNotifyBinding(property, target, targetProperty, type)
        @_bindings.notify[property] ?= []
        @_bindings.notify[property].push({attr:targetProperty, target: target, transferable: transferable})
        if target instanceof MztObject
          target._createBinding(targetProperty, @, property, MztObject.OBSERVE, transferable)
        @_doNotifyBinding(property)

      when MztObject.OBSERVE
        return if @_hasObserveBinding(property, target, targetProperty, type)
        unless target instanceof MztObject
          Util.warn "Binding #{property}ObserveBinding on",@,": target",target,"is not a MztObject"
          return

        @_bindings.observe[property] ?= []
        @_bindings.observe[property].push({attr:targetProperty, target: target, transferable: transferable})
        target._createBinding(targetProperty, @, property, MztObject.NOTIFY, transferable)
          
      when MztObject.SYNC
        @_createBinding(property, target, targetProperty, MztObject.OBSERVE, transferable)
        @_createBinding(property, target, targetProperty, MztObject.NOTIFY, transferable)

  # Remove the specified binding from this instance
  # @param [string] property The property on this instance that is observing
  # @param [MztObject] target The target MztObject 
  # @param [string] targetProperty The property on the target that is notifying
  # @param [constant] The type of the binding [ MztObject.NOTIFY, MztObject.OBSERVE, MztObject.SYNC ]
  # @private
  _removeBinding: (property, target, targetProperty, type) ->
    switch type
      when MztObject.NOTIFY
        return unless @_hasNotifyBinding(property, target, targetProperty)

        bindingset = []

        for binding in @_bindings.notify[property]
          bindingset.push binding unless binding.attr==targetProperty and binding.target._mozartId==target._mozartId
 
        unless bindingset.length == 0
          @_bindings.notify[property] = bindingset
        else
          delete @_bindings.notify[property]

        if target instanceof MztObject
          target._removeBinding(targetProperty, @, property, MztObject.OBSERVE)

      when MztObject.OBSERVE
        return unless @_hasObserveBinding(property, target, targetProperty)
        
        bindingset = []
        for binding in @_bindings.observe[property]
          bindingset.push binding unless binding.attr==targetProperty and binding.target._mozartId==target._mozartId
          
        unless bindingset.length == 0
          @_bindings.observe[property] = bindingset
        else
          delete @_bindings.observe[property]

        if target instanceof MztObject
          target._removeBinding(targetProperty, @, property, MztObject.NOTIFY)

      when MztObject.SYNC
        @_removeBinding(property, target, targetProperty, MztObject.NOTIFY)
        @_removeBinding(property, target, targetProperty, MztObject.OBSERVE)

  # Remove all bindings from this instance
  # @private
  _removeAllBindings: ->
    @_stripObserveBindings(false)
    @_stripNotifyBindings(false)

  # Notify (set) observing properties on all MztObjects observing the given attribute
  # @param [string] key The name of the attribute to notify
  # @private
  _doNotifyBinding: (key) ->
    bindings = @_bindings.notify[key]
    return unless bindings?
    for binding in bindings
      if binding?
        if Util.isFunction(binding.target.set)
          binding.target.set(binding.attr, @get(key))
        else
          binding.target[binding.attr] = @get(key)

  # Create declarative lookups for properties of this instance with the Lookup suffix by resolving their values and creating their properties on this instance
  # @private
  _createLookups: ->
    for key,v of @ when !Util.isFunction(@[key]) and Util.stringEndsWith(key, "Lookup")
      key = Util.sliceStringBefore(key, "Lookup")
      @[key] = Util._getPath(v)

exports.MztObject = MztObject
      

