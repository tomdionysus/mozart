Util = require './util'
{MztObject} = require './object'

# Instance represents a single item in a Model. It is conceptually equivalent to a database
# row.
#
# Instances should not be created directly - use the initInstance or createFromValues methods
# on the model itself
class Instance extends MztObject

  MODELFIELDS = ['id']

  # Initialise the instance, saving the Model name onto _type.
  init: ->
    @_type = @modelClass.modelName

  # If a backend store (ajax, localstorage) is defined, load the instance from that 
  # backend store by calling the loadInstance method with the specified options on 
  # the Model.
  # @param [object] options The options to pass to the Model loadInstance method.
  load: (options) =>
    options ?= {}
    @modelClass.loadInstance(@, options)

  # If a backend store (ajax, localstorage) is defined save the instance to that
  # store by calling either createInstance or updateInstance on the Model with the 
  # specified options, depending on whether the instance exists in the model.
  # @param [object] options The options to pass to the relevant Model method.
  save: (options) =>
    options ?= {}
    unless @modelClass.exists(@id)
      @modelClass.createInstance(@, options)
      @publish('create')
    else
      @modelClass.updateInstance(@, options)
      @publish('update')
    @publish('change')

  # Destroy the instance in one of the backend stores (ajax, localstorage) passing
  # the specified options by calling the destroyInstance method on the Model. 
  # @param [object] options The options to pass to the Model destroyInstance method.
  destroy: (options) =>
    options ?= {}
    @publish('destroy', options)
    @publish('change')
    @modelClass.destroyInstance(@, options)

  # Get the value of the specified attribute on this instance.
  # @param [string] key The name of the attribute.
  get: (key) =>
    if @modelClass.hasAttribute(key) or Util.isFunction(@[key])
      if Util.isFunction(@[key])
        @[key].apply(@)
      else
        super(key)
    else
      throw new Error "#{@modelClass.modelName} has no attribute or relation '#{key}' or foreign key '#{key}_id'"

  # Set the value of the specified attribute on this instance, updating the Model index if defined.
  # @param [string] key The name of the attribute.
  # @param [variant] value The new value of the attribute.
  set: (key, value) =>
    if @modelClass.hasAttribute(key) or Util.isFunction(@[key])
      if Util.isFunction(@[key])
        @[key](value)
      else
        if key!='id' and @modelClass.hasIndex(key) and @modelClass.exists(@id)
          @modelClass.updateIndex(key, @, @[key], value)
        super(key, value)
    else
      throw new Error "#{@modelClass.modelName} has no attribute or relation '#{key}' or foreign key '#{key}_id'"

  # Copy all defined attribute values to the supplied object and return it.
  # If object is not supplied, copyTo will create a new MztObject, copy to it, and return it.
  # @param [object] object (Optional) The object to copy the attributes and values to.
  copyTo: (object) =>
    object ?= MztObject.create()
    for attr,type of @modelClass.attrs when attr not in MODELFIELDS
      if object.set?
        object.set(attr,@[attr])
      else
        object[attr] = @[attr]
    object

  # Copy all defined attribute values from the supplied object and return a boolean specifying
  # whether any attribute values have now changed.
  # @param [object] object The object to copy values from
  # @return [boolean] Return true if any attribute values on this instance have now changed
  copyFrom: (object) =>
    changed = false
    for attr, value of object when attr not in MODELFIELDS
      type = @modelClass.attrs[attr]
      if type?
        newval = value
        newval = parseFloat(newval) if type == 'decimal' 
        if @[attr] != newval
          changed = true
          @set(attr,newval)
    changed

exports.Instance = Instance