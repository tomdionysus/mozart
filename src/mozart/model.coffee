Util = require './util'
{MztObject} = require './object'
{DataIndex} = require './data-index'
{Instance} = require './model-instance'
{InstanceCollection} = require './model-instancecollection'
{OneToManyCollection} = require './model-onetomanycollection'
{OneToManyPolyCollection} = require './model-onetomanypolycollection'
{ManyToManyCollection} = require './model-manytomanycollection'
{ManyToManyPolyCollection} = require './model-manytomanypolycollection'
{ManyToManyPolyReverseCollection} = require './model-manytomanypolyreversecollection'

# Model is the Mozart class that represents a data model and its store.
# Models in Mozart are instances of Mozart.Model, not descendants, and records
# in that datamodel are instances of Mozart.Instance, not the Mozart.Model they relate to.
#
# Mozart Models and relations are conceptually similar to actual database tables, in that
# The Model is the table, Instances are rows, and all relations are handled by foreign key
# attributes and their values.
#
# For more information, see http://www.mozart.io/model_demo
class Model extends MztObject
  @idCount = 1
  @indexForeignKeys = true
  @models = {}

  toString: ->
    "Model: #{@.modelName}"

  # Initialise the Model, checking modelName and setting up the instanceClass.
  init: ->
    Util.warn "Model must have a modelName", @ unless @modelName?

    @records = {}
    @fks = {}
    @polyFks = {}
    @attrs =
      id: 'integer'
    @relations = {}
    @indexes = {}

    Model.models[@modelName] = @

    @instanceClass = class ModelInstance extends Instance

  # Reset the model by releasing all instances and clearing all indexes.
  reset: =>
    inst.release() for id, inst of @records
    @records = {}
    @rebuildAllIndexes()

  # Add attributes to the Model
  # @param [object] attrs A map of attribute names to types 
  attributes: (attrs)  =>
    @attrs[k] = v for k,v of attrs

  # Find if the model has the specified attribute or foreign key
  # @param [string] attrName The name of the attribute to check for
  # @return [boolean] Return true if the attribute exists.
  hasAttribute: (attrName) ->
    (@attrs[attrName]?) or (@fks[attrName+"_id"]?)

  # Find if the model has the specified relation
  # @param [string] relationName The name of the relation to check for
  # @return [boolean] Return true if the relation exists.
  hasRelation: (relationName) ->
    (@relations[relationName]?)

  # Add foreign keys to the Model, indexing them if DataIndexForeignKeys is true
  # @param [object] foreignKeys A map of foreign keys names to models
  foreignKeys: (foreignKeys) =>
    for k,v of foreignKeys
      @fks[k] = v
      if Model.DataIndexForeignKeys then @index k

  # Add polymorphic foreign keys to the Model, indexing them if DataIndexForeignKeys 
  # is true
  # @param [object] foreignKeys A map of foreign keys names to models
  polyForeignKeys: (foreignKeys)  =>
    for k,v of foreignKeys
      @polyFks[k] = v
      if Model.DataIndexForeignKeys then @index k

  # belongsTo - General use belongsTo relation. The foreign key exists on 
  # this, the declaring model and points to the other model.
  # Note: belongsTo is the opposite side of a hasOne or a hasMany relation
  # If attribute or fkname are not supplied, the relation will be the snake case
  # of the other model modelName and the foreign key will be this model's snake case name 
  # suffixed with _id.
  # @param [Model] model The other model
  # @param [string] attribute (optional) The relation name - the method on each instance to get the relation object
  # @param [string] fkname (optional) The foreign key attribute name
  belongsTo: (model, attribute, fkname)  =>
    # get the attribute name and fk and add them to this model
    attribute ?= @toSnakeCase(model.modelName) unless attribute?
    fk = {}
    fkname ?= attribute+"_id"
    fk[fkname] = 'integer'
    @attributes fk
    fkn = {}
    fkn[fkname] = model
    @foreignKeys fkn

    # add the property function to this model instanceClass
    obj = {}

    obj[attribute] = (value) ->
      if arguments.length == 1
        unless (value==null or (value.modelClass? and value.modelClass is model))
          throw new Error "Cannot assign "+value+" to belongsTo "+@modelClass.modelName+":"+attribute+" (Value is not an Instance or incorrect ModelClass)"
        if value?
          @set(fkname,value.id)
        else
          @set(fkname,null)
      else
        id = @[fkname]
        return null unless id?
        model.findById(id)
    
    @instanceClass.extend(obj)

    Xthis = @
    # register to reset this fkey on delete of that model
    onDelete = (instance) ->
      for inst in model.findByAttribute(fkname, instance.id)
        inst.set(fkname,null)
        inst.save()

    model.subscribe('destroy', onDelete)

  # hasOne - General use hasOne relation. The foreign key exists on the supplied
  # model and points to this the declaring model. Only a single record in the other
  # model is allow to point each record in this model
  # - hasOne is an opposite side of a belongsTo relation
  # If attribute or fkname are not supplied, the relation will be the snake case
  # of the other model modelName and the foreign key will be this model's snake case modelName 
  # suffixed with _id.
  # @param [Model] model The other model
  # @param [string] attribute (optional) The relation name - the method on each instance to get the relation object
  # @param [string] fkname (optional) The foreign key attribute name on the other model
  hasOne: (model, attribute, fkname) ->
    attribute ?= @toSnakeCase(@modelName)
    fk = {}
    fkname ?= attribute+"_id"
    fk[fkname] = 'integer'
    model.attributes fk
    fkn = {}
    fkn[fkname] = @
    model.foreignKeys fkn

    @instanceClass::[attribute] = (value) ->
      if arguments.length == 1
        # setting
        for inst in model.findByAttribute(fkname, @id)
          if inst!=value
            inst.set(fkname, null) 
            inst.save()
        return if value == null
        value.set(fkname, @id)
        value.save()
        @publish('change:'+attribute)
        @publish('change')
      else
        # getting
        l = model.findByAttribute(fkname, @id)
        return null unless l.length>0
        l[0]

    Xthis = @

    onDelete = (instance) ->
      for inst in model.findByAttribute(fkname, instance.id)
        inst.set(fkname,null)
        inst.save()

    @subscribe('destroy', onDelete)
    
  # belongsToPoly - Polymorphic belongsTo. The foreign key and type exist on
  # this the declaring model and point to the other model when the
  # type field contains this model name.
  # - belongsToPoly is the opposite side of a hasManyPoly relation.
  # If attribute, fkname or fktypename are not supplied, the relation will be the snake 
  # case of the other model modelName and the foreign key and type will be that suffixed 
  # with _id and _type
  # @param [Model] model The other model
  # @param [string] attribute (optional) The relation name - the method on each instance to get the relation object
  # @param [string] fkname (optional) The foreign key attribute name on this model
  # @param [string] fktypename (optional) The foreign key type attribute name on this model
  belongsToPoly: (models, attribute, fkname, fktypename)  =>
    # get the attribute name and fk and add them to this model
    attribute ?= @toSnakeCase(model.modelName)
    fk = {}
    fkname ?= attribute+"_id"
    fk[fkname] = 'integer'
    fktypename ?= attribute+"_type"
    fk[fktypename] = 'string'
    @[attribute+"_allowed_models"] = models
    @attributes fk
    fkn = {}
    fkn[fkname] = fktypename
    @polyForeignKeys fkn

    # add the property function to this model instanceClass
    obj = {}

    obj[attribute] = (value, options) ->
      if arguments.length > 0
        if value?
          if !_.contains(models,value.modelClass)
            Util.error("Cannot assign a model of type {value.modelClass.modelName} to this belongsToPoly - allowed model types are "+models.join(', '))
          @set(fkname,value.id)
          @set(fktypename,value.modelClass.modelName)
        else
          @[fkname] = null
          @[fktypename] = null
        @save(options)
      else
        id = @[fkname]
        modelClass = Model.models[@[fktypename]]
        return null unless id? and modelClass?
        modelClass.findById(id)
    
    @instanceClass.extend(obj)

    Xthis = @

    # register to reset this fkey on delete of the other model
    onDelete = (instance, options={}) ->
      query = {}
      query[fkname] = instance.id
      query[fktypename] = instance.modelClass.modelName
      for inst in Xthis.findByAttributes(query)
        inst.set(fkname,null)
        inst.set(fktypename,null)
        inst.save(options)

    for model in models
      model.subscribe('destroy', onDelete)

  # hasMany - A general use hasMany relation where the foreign key
  # exists on the other model and points to this the declaring model
  # - hasMany is the opposite side of a belongsTo relation
  # If attribute or fkname are not supplied, the relation will be the snake 
  # case of the other model modelName and the foreign key will be this model's snake case 
  # modelName suffixed with _id 
  # @param [Model] model The other model
  # @param [string] attribute (optional) The relation name - the method on each instance to get the relation object
  # @param [string] fkname (optional) The foreign key attribute name on the other model
  hasMany: (model, attribute, fkname) =>
    # get the attribute name and fk and add them to the other model
    attribute ?= @toSnakeCase(model.modelName)
    fk = {}
    fkname ?= @toSnakeCase(@modelName+"_id")
    fk[fkname] = 'integer'
    model.attributes fk
    fkn = {}
    fkn[fkname] = @
    model.foreignKeys fkn

    @relations[attribute] = 
      type: 'hasMany'
      otherModel: model
      foreignKeyAttribute: fkname

    # add the property function to this model instanceClass
    Xthis = @
    obj = {}
    obj[attribute] = (value) ->
      if arguments.length > 0
        throw new Error "Cannot set a hasMany relation"
      unless @[attribute+"_hasMany_collection"]?
        @[attribute+"_hasMany_collection"] = OneToManyCollection.create
          record: @
          attribute: @attribute
          model: Xthis
          otherModel: model
          fkname: fkname
      @[attribute+"_hasMany_collection"]

    @instanceClass.extend(obj)

    # register to reset the other fkey on delete of this model
    onDelete = (instance, options={}) ->
      for inst in model.findByAttribute(fkname, instance.id)
        inst.set(fkname,null)
        inst.save(options)

    @subscribe('destroy', onDelete)

  # hasManyPoly - A polymorphic hasMany relation where the foreign key and type
  # exist on the other model and points to this the declaring model when 
  # the type field is this model name.
  # - hasManyPoly is the opposite side of a belongsToPoly relation 
  # If attribute, thatFkAttr or thatTypeAttr are not supplied, the relation will be the 
  # snake  case of the other model modelName and the foreign key and type will be this 
  # model's snake case modelName suffixed with _id and _type
  # @param [Model] model The other model
  # @param [string] attribute (optional) The relation name - the method on each instance to get the relation object
  # @param [string] thatFkAttr (optional) The foreign key attribute name on this model
  # @param [string] thatTypeAttr (optional) The foreign key type attribute name on this model
  hasManyPoly: (model, attribute, thatFkAttr, thatTypeAttr) ->
    attribute ?= @toSnakeCase(model.modelName) 
    thatFkAttr ?= attribute+"_id"
    thatTypeAttr ?= attribute+"_type"
    
    fk = {}
    fk[thatFkAttr] = 'integer'
    fk[thatTypeAttr] = 'string'
    model.attributes fk
    fkn = {}
    fkn[thatFkAttr] = thatTypeAttr
    model.polyForeignKeys fkn

    @relations[attribute] = 
      type: 'hasManyPoly'
      otherModel: model
      foreignKeyAttribute: thatFkAttr
      foreignModelTypeAttribute: thatTypeAttr

    # add the property function to this model instanceClass
    Xthis = @
    @instanceClass::[attribute] = (value) ->
      if arguments.length > 0
        throw new Error "Cannot set a hasManyPoly relation"
      unless @[attribute+"_hasManyPoly_collection"]?
        @[attribute+"_hasManyPoly_collection"] = OneToManyPolyCollection.create
          record: @
          model: Xthis
          otherModel: model
          thatFkAttr: thatFkAttr
          thatTypeAttr: thatTypeAttr
      @[attribute+"_hasManyPoly_collection"]

    # add a function to watch deletes on this model
    onDeleteF = (instance, options={}) ->
      query = {}
      query[thatFkAttr] = instance.id
      query[thatTypeAttr] = Xthis.modelName
      for inst in model.findByAttributes query
        inst.set(thatFkAttr,null)
        inst.set(thatTypeAttr,null)
        inst.save(options)

    @subscribe('destroy', onDeleteF)

  # hasManyThrough is a general use many to many relation using a linktable
  # where the foreign keys on both sides exist on an intermediate link model.
  #
  # If attribute, thisFkAttr or thatFkAttr are not supplied, the relation will be the snake 
  # case of the other model modelName, thisFkAttr will be this model's snake case 
  # modelName suffixed with _id and thatFkAttr will be the other model's snake case 
  # modelName suffixed with _id 
  # @param [Model] model The other model
  # @param [string] attribute (optional) The relation name - the method on each instance to get the relation object
  # @param [Model] linkModel The link model
  # @param [string] thisFkAttr (optional) The foreign key attribute name for this model on the link model
  # @param [string] thatFkAttr (optional) The foreign key attribute name for the other model on the link model
  hasManyThrough: (model, attribute, linkModel, thisFkAttr, thatFkAttr) =>
    # get the attribute name and fks and add them to the LINK model
    attribute ?= @toSnakeCase(model.modelName) 
    fk = {}
    thisFkAttr ?= @toSnakeCase(@modelName+"_id")
    thatFkAttr ?= @toSnakeCase(model.modelName)+"_id"
    fk[thisFkAttr] = 'integer'
    fk[thatFkAttr] = 'integer'
    linkModel.attributes fk
    fkn = {}
    fkn[thisFkAttr] = @
    fkn[thatFkAttr] = model
    linkModel.foreignKeys fkn

    @relations[attribute] = 
      type: 'hasManyThrough'
      otherModel: model
      linkModel: linkModel
      foreignKeyAttribute: thisFkAttr
      otherModelForeignKeyAttribute: thatFkAttr

    # add the property function to this model instanceClass
    Xthis = @

    @instanceClass::[attribute] = (value) ->
      if arguments.length > 0
        throw new Error "Cannot set a hasManyThrough relation"
      unless @[attribute+"_hasManyThrough_collection"]?
        @[attribute+"_hasManyThrough_collection"] = ManyToManyCollection.create
          record: @
          model: Xthis
          otherModel: model
          linkModel: linkModel
          thisFkAttr: thisFkAttr
          thatFkAttr: thatFkAttr
      @[attribute+"_hasManyThrough_collection"]

    # add a function to watch deletes on this or that model
    onDeleteF = (instance, options={}) ->
      for link in linkModel.findByAttribute(thisFkAttr, instance.id)
        link.destroy(options)
    @subscribe('destroy', onDeleteF)
    
    onDeleteB = (instance, options={}) ->
      for link in linkModel.findByAttribute(thatFkAttr, instance.id)
        link.destroy(options)
    model.subscribe('destroy', onDeleteB)

  # hasManyThroughPoly is a polymorphic many-to-many relation where both foreign 
  # keys and the type exist on a linkmodel.
  # - hasManyThroughPoly is the opposite side of a hasManyThroughPolyReverse relation
  # If attribute, thatFkAttr, thatTypeAttr or thatTypeAttr are not supplied, the relation 
  # will be the snake case of the other model modelName, thisFkAttr will be this model's 
  # snake case modelName suffixed with id, thatFkAttr and thatTypeAttr will be the other 
  # model's snake_case with _id and _type.
  # @param [Model] model The other model
  # @param [string] attribute (optional) The relation name - the method on each instance to get the relation object
  # @param [string] thisFkAttr (optional) The foreign key attribute name for this model on the link model
  # @param [string] thatFkAttr (optional) The foreign key attribute name for the other model on the link model
  # @param [string] thatTypeAttr (optional) The foreign key type attribute name for the other model on the link model
  hasManyThroughPoly: (model, attribute, linkModel, thisFkAttr, thatFkAttr, thatTypeAttr) ->
    # get the attribute name, fk, id and type fields and add them to the link model
    attribute ?= @toSnakeCase(model.modelName) 
    thisFkAttr ?= @toSnakeCase(@modelName+"_id")
    thatFkAttr ?= attribute+"_id"
    thatTypeAttr ?= attribute+"_type"
    fk = {}
    fk[thisFkAttr] = 'integer'
    fk[thatFkAttr] = 'integer'
    fk[thatTypeAttr] = 'string'
    linkModel.attributes fk
    fkn = {}
    fkn[thisFkAttr] = @
    linkModel.foreignKeys fkn
    fkn = {}
    fkn[thatFkAttr] = thatTypeAttr
    linkModel.polyForeignKeys fkn

    @relations[attribute] = 
      type: 'hasManyThroughPoly'
      otherModel: model
      linkModel: linkModel
      foreignKeyAttribute: thisFkAttr
      otherModelForeignKeyAttribute: thatFkAttr
      otherModelModelTypeAttribute: thatTypeAttr

    # add the property function to this model instanceClass
    Xthis = @
    @instanceClass::[attribute] = (value) ->
      if arguments.length > 0
        throw new Error "Cannot set a hasManyThroughPoly relation"
      unless @[attribute+"_hasManyThroughPoly_collection"]?
        @[attribute+"_hasManyThroughPoly_collection"] = ManyToManyPolyCollection.create
          record: @
          model: Xthis
          otherModel: model
          linkModel: linkModel
          thisFkAttr: thisFkAttr
          thatFkAttr: thatFkAttr
          thatTypeAttr: thatTypeAttr
      @[attribute+"_hasManyThroughPoly_collection"]

    # add a function to watch deletes on this or that model
    onDeleteF = (instance, options={}) ->
      query = {}
      query[thisFkAttr] = instance.id
      for link in linkModel.findByAttributes query
        link.destroy(options)
    @subscribe('destroy', onDeleteF)
    
    onDeleteB = (instance, options={}) ->
      query = {}
      query[thatFkAttr] = instance.id
      query[thatTypeAttr] = instance.modelClass.modelName
      for link in linkModel.findByAttributes query
        link.destroy(options)
    model.subscribe('destroy', onDeleteB)

  # hasManyThroughPolyReverse is a polymorphic many-to-many relation where both foreign 
  # keys and the type exist on a linkmodel.
  # - hasManyThroughPolyReverse is the opposite side of a hasManyThroughPoly relation
  # If attribute, thatFkAttr, thatTypeAttr or thatTypeAttr are not supplied, the relation 
  # will be the snake case of the other model modelName, thisFkAttr will be this model's 
  # snake case modelName suffixed with id, thatFkAttr and thatTypeAttr will be the other 
  # model's snake_case with _id and _type.
  # @param [Model] model The other model
  # @param [string] attribute (optional) The relation name - the method on each instance to get the relation object
  # @param [string] thisFkAttr (optional) The foreign key attribute name for this model on the link model
  # @param [string] thatFkAttr (optional) The foreign key attribute name for the other model on the link model
  # @param [string] thatTypeAttr (optional) The foreign key type attribute name for the other model on the link model
  hasManyThroughPolyReverse: (model, attribute, linkModel, thisFkAttr, thatFkAttr, thatTypeAttr) ->
    attribute ?= @toSnakeCase(model.modelName) 
    thisFkAttr ?= @toSnakeCase(@modelName+"_id")
    thatFkAttr ?= attribute+"_id"
    thatTypeAttr ?= attribute+"_type"

    @relations[attribute] = 
      type: 'hasManyThroughPolyReverse'
      otherModel: model
      linkModel: linkModel
      foreignKeyAttribute: thisFkAttr
      otherModelForeignKeyAttribute: thatFkAttr
      otherModelModelTypeAttribute: thatTypeAttr

    unless (linkModel.fks[thisFkAttr]? and linkModel.polyFks[thatFkAttr]? and linkModel.polyFks[thatFkAttr]!= thatTypeAttr?)
      Util.warn("hasManyThroughPolyReverse - #{thisFkAttr}, #{thatFkAttr} or #{thatTypeAttr} do not exist on link model '#{linkModel.modelName}' - there should be an existing hasManyThroughPoly to support this hasManyThroughPolyReverse")

    Xthis = @
    @instanceClass::[attribute] = (value) ->
      if arguments.length > 0
        throw new Error "Cannot set a hasManyThroughPolyReverse relation"
      unless @[attribute+"_hasManyThroughPolyReverse_collection"]?
        @[attribute+"_hasManyThroughPolyReverse_collection"] = ManyToManyPolyReverseCollection.create
          record: @
          model: Xthis
          otherModel: model
          linkModel: linkModel
          thisFkAttr: thisFkAttr
          thatFkAttr: thatFkAttr
          thatTypeAttr: thatTypeAttr
      @[attribute+"_hasManyThroughPolyReverse_collection"]

  # Methods

  # Get all Instances in the Model as an array
  # @return [array] Returns an array of all model Instances in this Model
  all: =>
    _(@records).values()

  # Get all Instances in the Model as a map of id => Instance
  # @return [object] Returns a map of all ids to Instances in this Model
  allAsMap: =>
    @records

  # Get the total count of Instances in the Model datastore.
  # @return [integer] Return the total count of Instances in the Model datastore.
  count: =>
    _(@records).keys().length

  # Get the numeric sum of the supplied field in all records
  sum: (attribute) =>
    sum = 0
    for id, inst of @records
      sum += inst[attribute] 
    sum

  # Get the numeric average of the supplied field in all records
  average: (attribute) =>
    count = @count()
    return undefined if count == 0
    @sum(attribute) / count

  # Get the Instance with the specified id
  # @param [string] id The Instance id to find
  # @return [Mozart.Instance] The Instance with the specified id, or NULL.
  findById: (id) =>
    return undefined unless id?
    @records[id]

  # Find all Instances with the specified array of ids
  # @param [array] ids An array of model instance ids
  # @return [array] An array of all found Instances, which may be smaller than ids.

  findAll: (ids) =>
    lst = []
    for id in ids
      if @exists(id)?
        lst.push @records[id] 
    lst

  # Get an array of Instances, one for each Instance in a query defined by the supplied 
  # callback. The callback will be called for each instance in the datastore, with the
  # Instance being passed as the first parameter, and should return true or false to select
  # that instance:
  # @example
  #   isIdOdd(instance) -> 
  #     return (instance.id mod 2 == 0)
  #
  #   oddPeople = App.People.select(@isIdOdd)
  #
  # Caveat: Do not modify the objects passed in the callback, this will confuse the iterator. If you need to modify a set of Instances, get them using select, then iterate them and modify.
  # @param [function] callback The function to filter the Instances, which should return true to select the instance passed.
  # @return [array] An array of selected instances 
  select: (callback) =>
    @findAll @selectIds callback

  # selectIds() returns an array of record ids, one for each record in
  # a query defined by the supplied callback. The callback function has
  # the same definition and constraints as select() above.
  # @param [function] callback The function to filter the Instances, which should return true to select the instance passed.
  # @return [array] An array of selected instances 
  selectIds: (callback) =>
    res = []
    for id, rec of @records
      if callback(rec) 
        res.push id
    res

  # selectAsMap is the same as selectIds() except it returns an
  # object instead of an array, with the id as the key and the record 
  # as the value 
  # @param [function] callback The function to filter the Instances, which should return true to select the instance passed.
  # @return [object] An map of the selected id -> Instance pairs
  selectAsMap: (callback) =>
    res = {}
    for id, rec of @records
      if callback(rec) 
        res[id] = rec
    res

  # Get all instances where attribute is equal to a value as an array, using
  # indexes if available
  # @param [string] attribute The attribute in which to search
  # @param [variant] value The value to search for
  # @return [array] An array of Instances found
  findByAttribute: (attribute, value) =>
    query = {}
    query[attribute] = value
    @findByAttributes query

  # Get all instances where a set of attributes are equal to a set of values as an array, 
  # using indexes if available
  # @param [object] attribute A map of attributes -> values to search for.
  # @return [array] An array of Instances found
  findByAttributes: (query) =>
    res = []
    for attributeName, value of query
      if @hasIndex(attributeName)
        res.push @getIndexFor(attributeName,value)
      else
        res.push @selectAsMap((rec) =>
          rec[attributeName] == value
        )
    out = res.pop() || {}
    while res.length>0
      res2 = res.pop()
      out2 = {}
      for i,k of res2
        if out[i]? then out2[i] = k
      out = out2
    _(out).values()

  # Find if an Instance with the specified id exists
  # @param [string] id The id to search for
  # @return [boolean] Returns true if the Instance exists
  exists: (id) =>
    @records[id]?

  # Instantiate but do not save an Instance of this model with the supplied attributes and 
  # values. The returned instance is not yet in the Model data store and cannot be used with 
  # indexes.
  # @param [object] data A map of attributes -> values to initialise the new Instance with.
  # @return [Mozart.Instance] The new instance
  initInstance: (data) =>
    inst = @_getInstance()
    for k, v of @attrs
      if data? and data[k]?
        inst.set(k,data[k])
      else
        inst.set(k, null)
    inst.set('id',@_generateId())
    inst

  # Create and save an Instance of this model with the supplied attributes and 
  # values.
  # @param [object] data A map of attributes -> values to initialise the new Instance with.
  # @return [Mozart.Instance] The new instance 
  createFromValues: (values) =>
    inst = @initInstance(values)
    inst.save()
    inst

  # Load the supplied instance from an external datastore (ajax, localstorage) by publishing
  # a load event on this model, which external datastores subscribe to when registered.
  # @param [Mozart.Instance] instance The instance to load
  # @param [object] options The options to pass to the load callback
  loadInstance: (instance, options={}) =>
    @publish 'load', instance

  # Create an existing instance by adding it to the model data store and indexing it, and
  # saving it to an external datastore if configured by publishing a create event on this 
  # model, which external datastores subscribe to when registered.
  # @param [Mozart.Instance] instance The instance to create
  # @param [object] options The options to pass to the load callback
  # @return [Mozart.Instance] The instance that has been created
  createInstance: (instance, options={}) =>
    id = instance.id
    if @exists(id)
      Util.error "createInstance: ID Already Exists",'collection',"model",@name,"id",id
    @records[id] = instance
    @addToIndexes(instance)
    @publish 'create', instance, options unless options.disableModelCreateEvent
    @publish 'change', instance, options unless options.disableModelChangeEvent
    instance

  # Update an existing instance by publishing an update event on this model, which 
  # external datastores subscribe to when registered.
  #
  # Please note this method does not modify the Instance, it just notifies any
  # configured external datastore that the model has been saved.
  # @param [Mozart.Instance] instance The instance to update
  # @param [object] options The options to pass to the update callback
  updateInstance: (instance, options={}) =>
    @publish 'update', instance, options unless options.disableModelUpdateEvent
    @publish 'change', instance, options unless options.disableModelChangeEvent
    id = instance.id
    unless @exists(id)
      Util.error "updateInstance: ID does not exist",'collection',"model",@name,"id",id

  # Destroy an existing instance by publishing an destroy event on this model, which 
  # external datastores subscribe to when registered.
  #
  # Please note this method does not release the Instance, it just removes it from
  # the model data store and indexes and notifies any configured external datastore 
  # that the model has been destroyed. 
  # @param [Mozart.Instance] instance The instance to destory
  # @param [object] options The options to pass to the destroy callback
  destroyInstance: (instance, options={}) =>
    id = instance.id
    unless @exists(id)
      Util.error "destroyInstance: ID does not exist",'collection',"model",@name,"id",id
    delete @records[instance.id]
    instance.modelClass.removeFromIndexes(instance)
    @publish 'destroy', instance, options unless options.disableModelDestroyEvent
    @publish 'change', instance, options unless options.disableModelChangeEvent

  # toSnakeCase translates CapsCase or camelCase to snake_case
  # Example:
  # toSnakeCase('People') = 'people'
  # toSnakeCase('PeopleTags') = 'people_tags'
  # toSnakeCase('methodName ') = 'method_name'
  # @param [string] name The original name
  # @return [string] The snake_case name
  toSnakeCase: (name) =>
    x = name.replace /[A-Z]{1,1}/g, (match) =>
      "_"+match.toLowerCase()
    x.replace /^_/, ''

  # Return a new, blank Instance configured with the model's modelClass
  # @return [Mozart.Instance] The new Instance
  # @private
  _getInstance: =>
    @instanceClass.create
      modelClass: @

  # Return a unique Instance client id and increment the global counter.
  # @return [string] A new client id of the format c-*n* where *n* is the global count.
  # @private
  _generateId: =>
    "c-"+(Model.idCount++)

  # Create an index on the specified attribute of the specified type and options.
  # If the index already exists, rebuild it.
  # @param [string] attrName The attribute to index
  # @param [string] type (optional) The type of the index, default is 'map'
  # @param [object] options (optional) The index options if required
  index: (attrName, type='map', options) =>
    unless @indexes[attrName]?
      idxClass = DataIndex.getIndexClassType(type)
      if idxClass?
        @indexes[attrName] = idxClass.create
          modelClass: @
          attribute: attrName
          options: options
        @['findBy'+attrName] = (needle) -> 
          @findByAttribute attrName, needle
        @['getBy'+attrName] = (needle) -> 
          @findByAttribute(attrName, needle)[0]
      else
        throw new Error "Model: Index Type #{type} is not supported"
    else
      @rebuildIndex(attrName)

  # Find if the Model has an index on the specified attribute
  # @param [string] attrName The attribute of the index
  # @return [boolean] Return true if an index exists on the attribute
  hasIndex: (attrName) ->
    (@indexes[attrName]?)

  # Get the index id map for the specified attribute and value.
  # @param [string] attrName The attribute of the index
  # @param [variant] value The value of the attribute
  # @return [object] A map of id -> Instance where attribute is equal to value
  getIndexFor: (attrName, value) ->
    throw new Error "Model.rebuildIndex: Index #{attrName} does not exist" unless @indexes[attrName]?
    @indexes[attrName].load(value)

  # Update an index with a given attribute name when an Instance has changed.
  # @param [string] attrName The attribute of the index
  # @param [Mozart.Instance] record The Instance that has changed
  # @param [variant] oldValue The previous value of the attribute in the Instance
  # @param [variant] newValue The new value of the attribute in the Instance
  updateIndex: (attrName, record, oldValue, newValue) ->
    throw new Error "Model.rebuildIndex: Index #{attrName} does not exist" unless @indexes[attrName]?
    @indexes[attrName].update(record, oldValue, newValue)

  # Add a specified Instance to all defined indexes
  # @param [Mozart.Instance] record The Instance to be added
  addToIndexes: (record) ->
    for attrName, index of @indexes
      index.add(record)

  # Remove a specified Instance from all defined indexes
  # @param [Mozart.Instance] record The Instance to be removed
  removeFromIndexes: (record) ->
    for attrName, index of @indexes
      index.remove(record)

  # Rebuild an index with a given attribute name
  # @param [string] attrName The attribute of the index to rebuild
  rebuildIndex: (attrName) ->
    throw new Error "Model.rebuildIndex: Index #{attrName} does not exist" unless @indexes[attrName]?
    @indexes[attrName].rebuild()

  # Drop an index with a given attribute name
  # @param [string] attrName The attribute of the index to drop
  dropIndex: (attrName) ->
    delete @indexes[attrName]
    delete @['findBy'+attrName]
    delete @['getBy'+attrName]

  # Rebuild all defined indexes
  rebuildAllIndexes: ->
    for attrName in _(@indexes).keys()
      @rebuildIndex(attrName)

exports.Model = Model
