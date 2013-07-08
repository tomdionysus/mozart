Util = require './util'
{MztObject} = require './object'

exports.InstanceCollection = class InstanceCollection extends MztObject
  count: =>
    @all().length

  allAsMap: =>
    Util.toMap(@all())

  all: ->
    []

  bindEvents: (models) =>
    for m in models
      m.subscribe('create', @onModelChange)
      m.subscribe('update', @onModelChange)
      m.subscribe('destroy', @onModelChange)

  unBindEvents: (models) =>
    for m in models
      m.unsubscribe('create', @onModelChange)
      m.unsubscribe('update', @onModelChange)
      m.unsubscribe('destroy', @onModelChange)