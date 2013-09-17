Util = require './util'
{MztObject} = require './object'

# DataIndex is the abstract base class for indexes.
#
# An DataIndex instance should have an 'attribute' property, defining
# the name of the attribute on the records to index, and a 'modelClass' property, defining
# the model on which the index is to operate
class DataIndex extends MztObject
  @indexTypes = {}

  init: ->
    Util.warn 'DataIndex must have an attribute', @ unless @attribute?
    Util.warn 'DataIndex must have a modelClass', @ unless @modelClass?

  load: ->
    throw new Error "Mozart.DataIndex: Abstract, Not Implemented"

  add: @load
  remove: @load
  update: @load
  rebuild: @load

  # Register an index type
  # @param idxType [string] The name of the index type
  # @param classType [class] The class which implements the index
  @registerIndexClassType: (idxType, classType) ->
    @indexTypes[idxType] = classType

  # Get the class for an index type
  # @param idxType [string] The name of the index type
  @getIndexClassType: (idxType) ->
    @indexTypes[idxType]

# A MapIndex builds a map of values to a map of {id:record} where record[attribute] 
# contains that value. MapIndex is the default case, a general purpose index.
#

class MapIndex extends DataIndex

  # Initialise the index. The 'attribute' and 'modelClass' properties should be passed 
  # to the options for create().
  init: ->
    super
    @map = {}
    @rebuild()

  # Load the index for a specified value
  # @param value [variant] The value to load the index for
  # @return [object] An map of ids to records, all with attributes equal to the value
  load: (value) ->
    if @map[value]?
      return @map[value]
    {}

  # Update the index for the specified record
  # @param record [object] The record
  # @param oldValue [variant] The previous value of the attribute
  # @param newValue [variant] The new value of the attribute
  update: (record, oldValue, newValue) ->
    if @map[oldValue]?
      delete @map[oldValue][record.id]
      if _(@map[oldValue]).keys().length == 0
        delete @map[oldValue]
    @map[newValue] ?= {}
    @map[newValue][record.id] = record

  # Add the specified record to the index
  # @param record [object] The record
  add: (record) ->
    @map[record[@attribute]] ?= {}
    @map[record[@attribute]][record.id] = record

  # Remove the specifed record from the index.
  # @param record [object] The record
  remove: (record) ->
    for value, ids of @map
      delete ids[record.id]
      if _(ids).keys().length == 0
        delete @map[value]

  # Rebuild the index from scratch with all records from the modelClass.
  rebuild: ->
    @map = {}
    for record in @modelClass.all()
      @add(record)


# A BooleanIndex builds two maps, one with each record where the 
# attribute is equal to the configured value, and one with each 
# record where it is not.
#
# The 'value' property defining the value for the index should be set in the options
# using create().
class BooleanIndex extends DataIndex

  # Initialise the index. The 'attribute', 'modelClass' and 'value' properties should 
  # be passed to the options for create().
  init: ->
    super
    @value = @options.value
    @rebuild()

  # Load the index for a specified value
  # @param value [variant] The value to load the index for
  # @return [object] An map of ids to records, all with attributes equal to the value
  load: (value) ->
    if value == @value
      @valueIds
    else
      @nonValueIds

  # Update the index for the specified record
  # @param record [object] The record
  # @param oldValue [variant] The previous value of the attribute
  # @param newValue [variant] The new value of the attribute
  update: (record, oldValue, newValue) ->
    if oldValue == @value
      delete @valueIds[record.id]
    else
      delete @nonValueIds[record.id]
    if newValue == @value
      @valueIds[record.id] = record
    else
      @nonValueIds[record.id] = record

  # Add the specified record to the index
  # @param record [object] The record
  add: (record) ->
    if record[@attribute] == @value
      @valueIds[record.id] = record
    else
      @nonValueIds[record.id] = record

  # Remove the specifed record from the index.
  # @param record [object] The record
  remove: (record) ->
    delete @valueIds[record.id]
    delete @nonValueIds[record.id]

  # Rebuild the index from scratch with all records from the modelClass.
  rebuild: ->
    @valueIds = {}
    @nonValueIds = {}
    for record in @modelClass.all()
      @add(record)

exports.DataIndex = DataIndex
exports.MapIndex = MapIndex
exports.BooleanIndex = BooleanIndex

DataIndex.registerIndexClassType('map', MapIndex)
DataIndex.registerIndexClassType('boolean', BooleanIndex)
