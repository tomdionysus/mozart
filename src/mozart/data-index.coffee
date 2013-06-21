{MztObject} = require './object'

exports.DataIndex = class DataIndex extends MztObject
  @indexTypes = {}

  load: ->
    throw new Error "Mozart.DataIndex: Abstract, Not Implemented"
  add: (record) ->
    throw new Error "Mozart.DataIndex: Abstract, Not Implemented"
  remove: (record) ->
    throw new Error "Mozart.DataIndex: Abstract, Not Implemented"
  update: (record, oldValue, newValue) ->
    throw new Error "Mozart.DataIndex: Abstract, Not Implemented"
  rebuild: () ->
    throw new Error "Mozart.DataIndex: Abstract, Not Implemented"

  @registerIndexClassType: (idxType, classType) ->
    @indexTypes[idxType] = classType

  @getIndexClassType: (idxType) ->
    @indexTypes[idxType]


# A MapIndex builds a map of values to a map of {id:record} where 
# the record[attribute] contains that value. 
# The default case, general purpose index.
exports.MapIndex = class MapIndex extends DataIndex

  init: ->
    @map = {}
    @rebuild()

  load: (value) ->
    if @map[value]?
      return @map[value]
    {}

  update: (record, oldValue, newValue) ->
    if @map[oldValue]?
      delete @map[oldValue][record.id]
      if _(@map[oldValue]).keys().length == 0
        delete @map[oldValue]
    @map[newValue] ?= {}
    @map[newValue][record.id] = record

  add: (record) ->
    @map[record[@attribute]] ?= {}
    @map[record[@attribute]][record.id] = record

  remove: (record) ->
    for value, ids of @map
      delete ids[record.id]
      if _(ids).keys().length == 0
        delete @map[value]

  rebuild: ->
    @map = {}
    for record in @modelClass.all()
      @add(record)

DataIndex.registerIndexClassType('map', MapIndex)

# A BooleanIndex builds two maps, one with each record where the 
# attribute is equal to the configured value, and one with each 
# record where it is not.
exports.BooleanIndex = class BooleanIndex extends DataIndex

  init: ->
    @value = @options.value
    @rebuild()

  load: (value) ->
    if value == @value
      @valueIds
    else
      @nonValueIds

  update: (record, oldValue, newValue) ->
    if oldValue == @value
      delete @valueIds[record.id]
    else
      delete @nonValueIds[record.id]
    if newValue == @value
      @valueIds[record.id] = record
    else
      @nonValueIds[record.id] = record

  add: (record) ->
    if record[@attribute] == @value
      @valueIds[record.id] = record
    else
      @nonValueIds[record.id] = record

  remove: (record) ->
    delete @valueIds[record.id]
    delete @nonValueIds[record.id]

  rebuild: ->
    @valueIds = {}
    @nonValueIds = {}
    for record in @modelClass.all()
      @add(record)

DataIndex.registerIndexClassType('boolean', BooleanIndex)
