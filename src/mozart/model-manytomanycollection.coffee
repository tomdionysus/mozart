{InstanceCollection} = require './model-instancecollection'

exports.ManyToManyCollection = class ManyToManyCollection extends InstanceCollection

  init: ->
    @bindEvents([@linkModel])
    
  all: =>
    links = @linkModel.findByAttribute(@thisFkAttr,@record.id)
    @otherModel.findById(link[@thatFkAttr]) for link in links

  add: (instance) =>
    query = {}
    query[@thisFkAttr] = @record.id
    query[@thatFkAttr] = instance.id
    if @linkModel.findByAttributes(query).length == 0
      linkInstance = @linkModel.initInstance()
      linkInstance.set(@thisFkAttr,@record.id)
      linkInstance.set(@thatFkAttr,instance.id)
      linkInstance.save()
      linkInstance

  createFromValues: (values) =>
    inst = @otherModel.initInstance(values)
    inst.save()
    @add(inst)
    inst

  remove: (instance) =>
    query = {}
    query[@thisFkAttr] = @record.id
    query[@thatFkAttr] = instance.id
    links = @linkModel.findByAttributes(query)
    for linkInstance in links
      linkInstance.destroy()

  contains: (instance) =>
    query = {}
    query[@thisFkAttr] = @record.id
    query[@thatFkAttr] = instance.id
    @linkModel.findByAttributes(query).length != 0

  onModelChange: (link) =>
    if link.get(@thisFkAttr) == @record.id
      instance = @otherModel.findById(link[@thatFkAttr])
      @trigger('change', instance)

  release: =>
    @unBindEvents([@linkModel])
    super