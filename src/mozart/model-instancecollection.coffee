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
      m.bind('create', @onModelChange)
      m.bind('update', @onModelChange)
      m.bind('destroy', @onModelChange)

  unBindEvents: (models) =>
    for m in models
      m.unbind('create', @onModelChange)
      m.unbind('update', @onModelChange)
      m.unbind('destroy', @onModelChange)