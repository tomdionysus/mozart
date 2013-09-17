{InstanceCollection} = require './model-instancecollection'

# OneToManyCollection is a relation class representing a scope of model instances in a one-to-many
# (hasMany) relation. Instances of this class are returned by relation methods created 
# by the hasMany method on Mozart.Model
#
# Please note that relation class do not actually contain lists of Instances. The relation
# class instance provides a set of scoped queries for the relation from the point of 
# view of the Instance that created it, having much the same interface as Mozart.Model
# allowing its use in collections, etc.
#
# For more information, see http://www.mozart.io/guides/understanding_relations
class OneToManyCollection extends InstanceCollection

  # Initialise the relation instance by subscribing to events on the other model
  init: ->
    @subscribeEvents([@otherModel])

  # Return all instances of the related model by querying the model where the foreign
  # key is equal to this relation owner's id
  # @return [array] An array of all related Mozart.Instance instances 
  all: =>
    @otherModel.findByAttribute(@fkname,@record.id)

  # Add an instance to the relation by setting its related foreign key to this relation
  # owner's id
  # @param [Mozart.Instance] instance The instance to add to the relation
  add: (instance) =>
    instance.set(@fkname, @record.id)
    instance.save()
    @record.publish("change:#{@attribute}")

  # Create and save an instance of the other model with the supplied attribute
  # values and add it to the relation.
  # @param [object] values A map of attributes and values to create the new instance with
  # @return [Mozart.Instance] The new other model instance 
  createFromValues: (values) =>
    inst = @otherModel.initInstance(values)
    @add(inst)
    inst
   
  # Remove an instance from the relation by clearing its associated foreign key
  # @param [Mozart.Instance] instance The instance to remove from the relation
  remove: (instance) =>
    instance.set(@fkname,null)
    @record.publish("change:#{@attribute}")

  # Query if the specified instance of the other model is in this relation by
  # checking if its related foreign key is equal to this relation owner's id 
  # @param [Mozart.Instance] instance The instance to search for in the relation
  # @return [boolean] Returns true if the instance exists in the relation
  contains: (instance) =>
    instance[@fkname] == @record.id

  # Called when a change happens on the other model, publish change on this relation.
  # @param [Mozart.Instance] instance The instance that changed
  # @private
  onModelChange: (instance) =>
    @publish('change', instance)

  # Release this relation instance, unsubscribing from all events on the other model.
  release: =>
    @unsubscribeEvents([@otherModel])
    super

exports.OneToManyCollection = OneToManyCollection