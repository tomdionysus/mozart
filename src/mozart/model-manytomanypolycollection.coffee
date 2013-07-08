{InstanceCollection} = require './model-instancecollection'

exports.ManyToManyPolyCollection = class ManyToManyPolyCollection extends InstanceCollection

  init: ->
    @bindEvents([@linkModel])

  # Return all instances in this relation
  all: =>
    query = {}
    query[@thisFkAttr] = @record.id
    query[@thatTypeAttr] = @otherModel.modelName
    links = @linkModel.findByAttributes query
    @otherModel.findById(link[@thatFkAttr]) for link in links

  createFromValues: (values) =>
    inst = @otherModel.initInstance(values)
    inst.save()
    @add(inst)
    inst

  add: (instance) =>
    query = {}
    query[@thisFkAttr] = @record.id
    query[@thatFkAttr] = instance.id
    query[@thatTypeAttr] =  @otherModel.modelName
    if @linkModel.findByAttributes(query).length == 0
      linkInstance = @linkModel.initInstance()
      linkInstance.set(@thisFkAttr,@record.id)
      linkInstance.set(@thatFkAttr,instance.id)
      linkInstance.set(@thatTypeAttr,@otherModel.modelName)
      linkInstance.save()
      linkInstance

  remove: (instance) =>
    query = {}
    query[@thisFkAttr] = @record.id
    query[@thatFkAttr] = instance.id
    query[@thatTypeAttr] = @otherModel.modelName
    for link in @linkModel.findByAttributes(query)
      link.destroy()

  contains: (instance) =>
    query = {}
    query[@thisFkAttr] = @record.id
    query[@thatFkAttr] = instance.id
    query[@thatTypeAttr] = @otherModel.modelName
    @linkModel.findByAttributes(query).length != 0

  onModelChange: (link) =>
    if link[@thisFkAttr] == @record.id && link[@thatTypeAttr] == @otherModel.modelName
      instance = @otherModel.findById(link[@thatFkAttr])
      @publish('change', instance)

  release: =>
    @unBindEvents([@linkModel])
    super