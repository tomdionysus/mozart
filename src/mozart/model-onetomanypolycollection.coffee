{InstanceCollection} = require './model-instancecollection'

exports.OneToManyPolyCollection = class OneToManyPolyCollection extends InstanceCollection

  all: =>
    query = {}
    query[@thatFkAttr] = @record.id
    query[@thatTypeAttr] = @model.modelName
    @otherModel.findByAttributes query

  createFromValues: (values) =>
    inst = @otherModel.initInstance(values)
    @add(inst)
    inst

  add: (instance) =>
    instance.set(@thatFkAttr,@record.id)
    instance.set(@thatTypeAttr,@model.modelName)
    instance.save()

  remove: (instance) =>
    instance.set(@thatFkAttr,null)
    instance.set(@thatTypeAttr,null)
    instance.save()

  contains: (instance) =>
    query = {}
    query[@thatFkAttr] = @record.id
    query[@thatTypeAttr] = @model.modelName
    @otherModel.findByAttributes(query).length != 0