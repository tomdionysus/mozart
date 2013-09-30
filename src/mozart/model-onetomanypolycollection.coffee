{InstanceCollection} = require './model-instancecollection'

# OneToManyPolyCollection is a relation class representing a scope of model instances in a 
# polymorphic one-to-many (hasManyPoly) relation. Instances of this class are returned by 
# relation methods created by the hasManyPoly method on Mozart.Model
#
# Please note that relation class do not actually contain lists of Instances. The relation
# class instance provides a set of scoped queries for the relation from the point of 
# view of the Instance that created it, having much the same interface as Mozart.Model
# allowing its use in collections, etc.
#
# For more information, see http://www.mozart.io/guides/understanding_relations
class OneToManyPolyCollection extends InstanceCollection

  # Return all instances of the related model by querying the model where the foreign
  # key and type is equal to this relation owner's id and model type
  # @return [array] An array of all related Mozart.Instance instances 
  all: =>
    query = {}
    query[@thatFkAttr] = @record.id
    query[@thatTypeAttr] = @model.modelName
    @otherModel.findByAttributes query

  # Create and save an instance of the other model with the supplied attribute
  # values and add it to the relation.
  # @param [object] values A map of attributes and values to create the new instance with
  # @return [Mozart.Instance] The new other model instance 
  createFromValues: (values) =>
    inst = @otherModel.initInstance(values)
    @add(inst)
    inst

  # Add an instance to the relation by setting its related foreign key and type to this 
  # relation owner's id and model type
  # @param [Mozart.Instance] instance The instance to add to the relation
  add: (instance) =>
    instance.set(@thatFkAttr,@record.id)
    instance.set(@thatTypeAttr,@model.modelName)
    instance.save()

  # Remove an instance from the relation by clearing its associated foreign key
  # and model type
  # @param [Mozart.Instance] instance The instance to remove from the relation
  remove: (instance) =>
    instance.set(@thatFkAttr,null)
    instance.set(@thatTypeAttr,null)
    instance.save()

  # Query if the specified instance of the other model is in this relation by
  # checking if its related foreign key and type are equal to this relation owner's 
  # id and model type 
  # @param [Mozart.Instance] instance The instance to search for in the relation
  # @return [boolean] Returns true if the instance exists in the relation
  contains: (instance) =>
    instance[@thatFkAttr] == @record.id and instance[@thatTypeAttr] == @model.modelName

exports.OneToManyPolyCollection = OneToManyPolyCollection