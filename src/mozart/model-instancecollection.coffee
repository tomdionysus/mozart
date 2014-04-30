Util = require './util'
{MztObject} = require './object'

# InstanceCollection is the abstract base class for all relation objects.
#
# For more information, see http://www.mozart.io/guides/understanding_relations
class InstanceCollection extends MztObject

  # The number of items in the collection
  # @return [integer] Returns the number of items in the collection
  count: =>
    @all().length

  # All the items in the collection as a map of id -> item
  # @return [object] Returns a map of id -> item for all items
  allAsMap: =>
    Util.toMap(@all())

  # All the items in the collection as an array
  # @return [array] All items in the collection
  all: ->
    []

  # Get the numeric sum of the supplied field in all records
  sum: (attribute) =>
    sum = 0
    sum += inst[attribute] for inst in @all()
    sum

  # Get the numeric average of the supplied field in all records
  average: (attribute) =>
    count = @count()
    return undefined if count == 0
    @sum(attribute) / count

  # Subscribe to create, update and destroy events on the supplied models
  # @param [array] models The array of models to subscribe to events on
  subscribeEvents: (models) =>
    for m in models
      m.subscribe('create', @onModelChange)
      m.subscribe('update', @onModelChange)
      m.subscribe('destroy', @onModelChange)

  # Unsubscribe to create, update and destroy events on the supplied models
  # @param [array] models The array of models to unsubscribe from events on
  unsubscribeEvents: (models) =>
    for m in models
      m.unsubscribe('create', @onModelChange)
      m.unsubscribe('update', @onModelChange)
      m.unsubscribe('destroy', @onModelChange)

exports.InstanceCollection = InstanceCollection