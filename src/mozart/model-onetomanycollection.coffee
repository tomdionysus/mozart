{InstanceCollection} = require './model-instancecollection'

exports.OneToManyCollection = class OneToManyCollection extends InstanceCollection

  init: ->
    @bindEvents([@otherModel])

  all: =>
    @otherModel.findByAttribute(@fkname,@record.id)

  add: (instance) =>
    instance.set(@fkname, @record.id)
    instance.save()
    @record.publish("change:#{@attribute}")

  createFromValues: (values) =>
    inst = @otherModel.initInstance(values)
    @add(inst)
    inst

  remove: (instance) =>
    instance.set(@fkname,null)
    @record.publish("change:#{@attribute}")

  contains: (instance) =>
    @otherModel.findByAttribute(@fkname,@record.id).length > 0

  onModelChange: (instance) =>
    @publish('change', instance)

  release: =>
    @unBindEvents([@otherModel])
    super