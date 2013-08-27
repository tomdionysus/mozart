Util = require './util'
{Events} = require './events'

exports.MztObject = class MztObject

  # Internal Constants
  MODULEKEYWORDS = ['extended', 'included']

  # Class Constants
  @NOTIFY: 2
  @OBSERVE: 1
  @SYNC: 0

  # Class Methods
  @include: (obj) ->
    for key, value of obj when key not in MODULEKEYWORDS
      @[key] = value

    obj.extended?.apply(@)
    this

  @extend: (obj) ->
    for key, value of obj when key not in MODULEKEYWORDS
      @::[key] = value

    obj.included?.apply(@)
    this

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

  # Instance Methods
  constructor: ->
    @_mozartId = Util.getId()

  toString: ->
    "obj-#{@_mozartId}"

  get: (key) ->
    if Util.isFunction(@[key])
      @[key].call(@)
    else
      @[key]

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

  bind: (args...) -> 
    console.warn "'bind' will be depreciated in Mozart 0.2.0. Please use 'subscribe'." if console?
    @subscribe(args...)
  subscribe: (args...) ->
    Events.subscribe(@_mozartId, args...)
    @

  one: (args...) ->
    console.warn "'one' will be depreciated in Mozart 0.2.0. Please use 'subscribeOnce'." if console?
    @subscribeOnce(args...)
  subscribeOnce: (args...) ->
    Events.subscribeOnce(@_mozartId, args...)
    @

  trigger: (args...) ->
    console.warn "'trigger' will be depreciated in Mozart 0.2.0. Please use 'publish'." if console?
    @publish(args...)
  publish: (args...) ->
    Events.publish(@_mozartId, args...)
    @

  unbind: (args...) ->
    console.warn "'unbind' will be depreciated in Mozart 0.2.0. Please use 'unsubscribe'." if console?
    @unsubscribe(args...)
  unsubscribe: (args...) ->
    Events.unsubscribe(@_mozartId, args...)
    @

  release: ->
    return if @released
    @_removeAllBindings()
    @unsubscribe()
    for own k,v of @
      @[k] = undefined
      delete @[k]
    @released = true

  # Private Methods
  _stripNotifyBindings: (transferOnly = false) ->
    bindings = {}
    for key, cbindings of @_bindings.notify
      bindings[key] = []
      for binding in cbindings when (!transferOnly or binding.transferable)
        bindings[key].push binding
        @_removeBinding(key, binding.target, binding.attr, MztObject.NOTIFY)
    bindings

  _addNotifyBindings: (bindingset) ->
    for key, bindings of bindingset
      for binding in bindings
        @_createBinding(key, binding.target, binding.attr, MztObject.NOTIFY, binding.transferable)

  _stripObserveBindings: (transferOnly = false)  ->
    bindings = {}
    for key, cbindings of @_bindings.observe
      bindings[key] = []
      for binding in cbindings when (!transferOnly or binding.transferable)
        bindings[key].push binding
        @_removeBinding(key, binding.target, binding.attr, MztObject.OBSERVE)
    bindings

  _addObserveBindings: (bindingset) ->
    for key, bindings of bindingset
      for binding in bindings
        @_createBinding(key, binding.target, binding.attr, MztObject.OBSERVE, binding.transferable)

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

  _hasNotifyBinding: (property, target, targetProperty, type) ->
    return false unless @_bindings.notify[property]?
    for binding in @_bindings.notify[property]
      return true if binding.attr==targetProperty and binding.target._mozartId==target._mozartId
    return false

  _hasObserveBinding: (property, target, targetProperty, type) ->
    return false unless @_bindings.observe[property]?
    for binding in @_bindings.observe[property]
      return true if binding.attr==targetProperty and binding.target._mozartId==target._mozartId
    return false

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

  _removeAllBindings: ->
    @_stripObserveBindings(false)
    @_stripNotifyBindings(false)

  _doNotifyBinding: (key) ->
    bindings = @_bindings.notify[key]
    return unless bindings?
    for binding in bindings
      if binding?
        if Util.isFunction(binding.target.set)
          binding.target.set(binding.attr, @get(key))
        else
          binding.target[binding.attr] = @get(key)

  _createLookups: ->
    for key,v of @ when !Util.isFunction(@[key]) and Util.stringEndsWith(key, "Lookup")
      key = Util.sliceStringBefore(key, "Lookup")
      @[key] = Util._getPath(v)
      

