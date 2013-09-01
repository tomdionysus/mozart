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

exports.Model = class Model extends MztObject
  @idCount = 1
  @indexForeignKeys = true
  @models = {}

  toString: ->
    "Model: #{@.modelName}"

  # Configuration
  init: ->
    unless @modelName?
      throw new Error "Model must have a modelName"

    @records = {}
    @fks = {}
    @polyFks = {}
    @attrs =
      id: 'integer'
    @relations = {}
    @indexes = {}

    Model.models[@modelName] = @

    @instanceClass = class ModelInstance extends Instance

  reset: =>
    for id, inst of @records
      inst.release()
    @records = {}
    @rebuildAllIndexes()

  attributes: (attrs)  =>
    for k,v of attrs
      @attrs[k] = v

  hasAttribute: (attrName) ->
    (@attrs[attrName]?) or (@fks[attrName+"_id"]?)

  hasRelation: (relationName) ->
    (@relations[relationName]?)

  foreignKeys: (foreignKeys) =>
    for k,v of foreignKeys
      @fks[k] = v
      if Model.DataIndexForeignKeys then @index k

  polyForeignKeys: (foreignKeys)  =>
    for k,v of foreignKeys
      @polyFks[k] = v
      if Model.DataIndexForeignKeys then @index k

  # belongsTo - General use belongsTo relation. The foreign key exists on 
  # this the declaring model and points to the other model.
  # - belongsTo is the opposite side of a hasOne or a hasMany relation
  belongsTo: (model, attribute, fkname)  =>
    # get the attribute name and fk and add them to THIS model
    attribute ?= @toSnakeCase(model.modelName) unless attribute?
    fk = {}
    fkname ?= attribute+"_id"
    fk[fkname] = 'integer'
    @attributes fk
    fkn = {}
    fkn[fkname] = model
    @foreignKeys fkn

    # add the property function to THIS model instanceClass
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
    # register to reset THIS fkey on delete of THAT model
    onDelete = (instance) ->
      for inst in model.findByAttribute(fkname, instance.id)
        inst.set(fkname,null)
        inst.save()

    model.subscribe('destroy', onDelete)

  # hasOne - General use hasOne relation. The foreign key exists on the supplied
  # model and points to this the declaring model. Only a single record in the other
  # model is allow to point each record in this model
  # - hasOne is an opposite side of a belongsTo relation
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
  belongsToPoly: (models, attribute, fkname, fktypename)  =>
    # get the attribute name and fk and add them to THIS model
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

    # add the property function to THIS model instanceClass
    obj = {}

    obj[attribute] = (value, options) ->
      if arguments.length > 0
        if value?
          if !_.contains(models,value.modelClass)
            Util.error("Cannot assign a model of type {{value.modelClass.modelName}} to this belongsToPoly - allowed model types are "+models.join(', '))
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

    # register to reset THIS fkey on delete of THAT model
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
  hasMany: (model, attribute, fkname) =>
    # get the attribute name and fk and add them to THAT model
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

    # add the property function to THIS model instanceClass
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

     # register to reset THAT fkey on delete of THIS model
    onDelete = (instance, options={}) ->
      for inst in model.findByAttribute(fkname, instance.id)
        inst.set(fkname,null)
        inst.save(options)

    @subscribe('destroy', onDelete)

  # hasManyPoly - A polymorphic hasMany relation where the foreign key and type
  # exist on the other model and points to this the declaring model when 
  # the type field is this model name.
  # - hasManyPoly is the opposite side of a belongsToPoly relation 
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

    # add the property function to THIS model instanceClass
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

    # add the property function to THIS model instanceClass
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
  hasManyThroughPoly: (model, attribute, linkModel, thisFkAttr, thatFkAttr, thatTypeAttr) ->
    # get the attribute name, fk, id and type fields and add them to the LINK model
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

    # add the property function to THIS model instanceClass
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

  all: =>
    _(@records).values()

  allAsMap: =>
    @records

  count: =>
    _(@records).keys().length

  findById: (id) =>
    return undefined unless id?
    @records[id]

  findAll: (ids) =>
    lst = []
    for id in ids
      if @exists(id)?
        lst.push @records[id] 
    lst

  # select() returns an array of Instances, one for each record in a
  # query defined by the supplied callback. The callback should take
  # one parameter, which is the raw object in the datastore.
  # Caveat: Do not modify the object passed in any way, indexing/events
  # will suffer accordingly if you do so. 
  select: (callback) =>
    @findAll @selectIds callback

  # selectIds() returns an array of record ids, one for each record in
  # a query defined by the supplied callback. The callback function has
  # the same definition and constraints as select() above.
  selectIds: (callback) =>
    res = []
    for id, rec of @records
      if callback(rec) 
        res.push id
    res

  # selectAsMap is the same as selectIds() except it returns an
  # object instead of an array, with the id as the key and the record 
  # as the value 
  # i.e. if select() returns [0,4,64,2]
  # selectAsMap() returns { 0:<record(0)>, 4:<record(4)>,
  # 64:<record(64)>, 2:<record(2)> }
  selectAsMap: (callback) =>
    res = {}
    for id, rec of @records
      if callback(rec) 
        res[id] = rec
    res

  findByAttribute: (attribute, value) =>
    query = {}
    query[attribute] = value
    @findByAttributes query

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

  exists: (id) =>
    @records[id]?

  initInstance: (data) =>
    inst = @_getInstance()
    for k, v of @attrs
      if data? and data[k]?
        inst.set(k,data[k])
      else
        inst.set(k, null)
    inst.set('id',@_generateId())
    inst

  createFromValues: (values) =>
    inst = @initInstance(values)
    inst.save()
    inst

  loadInstance: (instance, options={}) =>
    @publish 'load', instance

  createInstance: (instance, options={}) =>
    id = instance.id
    if @exists(id)
      Util.error "createInstance: ID Already Exists",'collection',"model",@name,"id",id
    @records[id] = instance
    @addToIndexes(instance)
    @publish 'create', instance, options unless options.disableModelCreateEvent
    @publish 'change', instance, options unless options.disableModelChangeEvent
    instance

  updateInstance: (instance, options={}) =>
    @publish 'update', instance, options unless options.disableModelUpdateEvent
    @publish 'change', instance, options unless options.disableModelChangeEvent
    id = instance.id
    unless @exists(id)
      Util.error "updateInstance: ID does not exist",'collection',"model",@name,"id",id

  destroyInstance: (instance, options={}) =>
    id = instance.id
    unless @exists(id)
      Util.error "destroyInstance: ID does not exist",'collection',"model",@name,"id",id
    delete @records[instance.id]
    instance.modelClass.removeFromIndexes(instance)
    @publish 'destroy', instance, options unless options.disableModelDestroyEvent
    @publish 'change', instance, options unless options.disableModelChangeEvent

  # INTERNAL Helpers

  # toSnakeCase translates CapsCase or camelCase to snake_case
  # Example:
  # toSnakeCase('People') = 'people'
  # toSnakeCase('PeopleTags') = 'people_tags'
  # toSnakeCase('methodName ') = 'method_name'
  toSnakeCase: (name) =>
    x = name.replace /[A-Z]{1,1}/g, (match) =>
      "_"+match.toLowerCase()
    x.replace /^_/, ''

  _getInstance: =>
    @instanceClass.create
      modelClass: @

  _generateId: () =>
    "c-"+(Model.idCount++)

  # Indexing

  index: (attrName, type='map', options) =>
    unless @indexes[attrName]?
      idxClass = DataIndex.getIndexClassType(type)
      if idxClass?
        @indexes[attrName] = idxClass.create
          modelClass: @
          attribute: attrName
          options: options
      else
        throw new Error "Model: Index Type #{type} is not supported"
    else
      @rebuildIndex(attrName)

  hasIndex: (attrName) ->
    (@indexes[attrName]?)

  getIndexFor: (attrName, value) ->
    throw new Error "Model.rebuildIndex: Index #{attrName} does not exist" unless @indexes[attrName]?
    @indexes[attrName].load(value)

  updateIndex: (attrName, record, oldValue, newValue) ->
    throw new Error "Model.rebuildIndex: Index #{attrName} does not exist" unless @indexes[attrName]?
    @indexes[attrName].update(record, oldValue, newValue)

  addToIndexes: (record) ->
    for attrName, index of @indexes
      index.add(record)

  removeFromIndexes: (record) ->
    for attrName, index of @indexes
      index.remove(record)

  rebuildIndex: (attrName) ->
    throw new Error "Model.rebuildIndex: Index #{attrName} does not exist" unless @indexes[attrName]?
    @indexes[attrName].rebuild()

  dropIndex: (attrName) ->
    delete @indexes[attrName]

  rebuildAllIndexes: ->
    for attrName in _(@indexes).keys()
      @rebuildIndex(attrName)
