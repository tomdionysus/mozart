{InstanceCollection} = require './model-instancecollection'

exports.ManyToManyPolyReverseCollection = class ManyToManyPolyReverseCollection extends InstanceCollection

  init: ->
    @bindEvents([@linkModel])

  all: =>
    query = {}
    query[@thatFkAttr] = @record.id
    query[@thatTypeAttr] = @model.modelName
    links = @linkModel.findByAttributes query
    @otherModel.findById(link[@thisFkAttr]) for link in links

  createFromValues: (values) =>
    inst = @otherModel.initInstance(values)
    inst.save()
    @add(inst)
    inst

  add: (instance) =>
    query = {}
    query[@thisFkAttr] = instance.id
    query[@thatFkAttr] = @record.id
    query[@thatTypeAttr] = @model.modelName
    if @linkModel.findByAttributes(query).length == 0
      linkInstance = @linkModel.initInstance()
      linkInstance.set(@thisFkAttr,instance.id)
      linkInstance.set(@thatFkAttr,@record.id)
      linkInstance.set(@thatTypeAttr,@model.modelName)
      linkInstance.save()
      linkInstance

  remove: (instance) =>
    query = {}
    query[@thisFkAttr] = instance.id
    query[@thatFkAttr] = @record.id
    query[@thatTypeAttr] = @model.modelName
    for link in @linkModel.findByAttributes(query)
      link.destroy()

  contains: (instance) =>
    query = {}
    query[@thisFkAttr] = instance.id
    query[@thatFkAttr] = @record.id
    query[@thatTypeAttr] = @model.modelName
    @linkModel.findByAttributes(query).length != 0

  onModelChange: (link) =>
    if link[@thatFkAttr] == @record.id && link[@thatTypeAttr] == @model.modelName
      instance = @model.findById(link[@thisFkAttr])
      @trigger('change', instance)

  release: =>
    @unBindEvents([@linkModel])
    super