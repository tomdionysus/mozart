Util = require './util'
{MztObject} = require './object'

exports.Instance = class Instance extends MztObject

  MODELFIELDS = ['id']

  init: ->
    @_type = @modelClass.modelName

  load: (options) =>
    options ?= {}
    @modelClass.loadInstance(@, options)

  save: (options) =>
    options ?= {}
    unless @modelClass.exists(@id)
      @modelClass.createInstance(@, options)
      @publish('create')
    else
      @modelClass.updateInstance(@, options)
      @publish('update')
    @publish('change')

  destroy: (options) =>
    options ?= {}
    @publish('destroy', options)
    @publish('change')
    @modelClass.destroyInstance(@, options)

  get: (key) =>
    if @modelClass.hasAttribute(key) or Util.isFunction(@[key])
      if Util.isFunction(@[key])
        @[key].apply(@)
      else
        super(key)
    else
      throw new Error "#{@modelClass.modelName} has no attribute or relation '#{key}' or foreign key '#{key}_id'"

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

  copyTo: (object) =>
    object ?= MztObject.create()
    for attr,type of @modelClass.attrs when attr not in MODELFIELDS
      if object.set?
        object.set(attr,@[attr])
      else
        object[attr] = @[attr]
    object

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