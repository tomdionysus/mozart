{InstanceCollection} = require './model-instancecollection'

# ManyToManyPolyReverseCollection is a relation class representing a scope of models in a 
# reverse polymorphic many-to-many (hasManyThroughPolyReverse) relation. Instances of this 
# class are returned by relation methods created by the hasManyThroughPolyReverse method on
# Mozart.Model 
#
# Please note that relation class do not actually contain lists of Instances. The relation
# class instance provides a set of scoped queries for the relation from the point of 
# view of the Instance that created it, having much the same interface as Mozart.Model
# allowing its use in collections, etc.
#
# For more information, see http://www.mozart.io/guides/understanding_relations
class ManyToManyPolyReverseCollection extends InstanceCollection

  # Initialise the relation instance by subscribing to events on the link model
  init: ->
    @subscribeEvents([@linkModel])

  # Return all instances of the related model by querying the link model and 
  # resolving the returned links
  # @return [array] An array of all related Mozart.Instance instances 
  all: =>
    query = {}
    query[@thatFkAttr] = @record.id
    query[@thatTypeAttr] = @model.modelName
    links = @linkModel.findByAttributes query
    @otherModel.findById(link[@thisFkAttr]) for link in links

  # Create and save an instance of the other model with the supplied attribute
  # values and add it to the relation.
  # @param [object] values A map of attributes and values to create the new instance with
  # @return [Mozart.Instance] The new other model instance 
  createFromValues: (values) =>
    inst = @otherModel.initInstance(values)
    inst.save()
    @add(inst)
    inst

  # Add an instance to the relation by creating a record in the link model
  # @param [Mozart.Instance] instance The instance to add to the relation
  add: (instance) =>
    query = {}
    query[@thisFkAttr] = instance.id
    query[@thatFkAttr] = @record.id
    query[@thatTypeAttr] = @model.modelName
    if @linkModel.findByAttributes(query).length == 0
      linkInstance = @linkModel.initInstance()
      linkInstance.set(@thisFkAttr,instance.id)
      linkInstance.set(@thatFkAttr,@record.id)
      linkInstance.set(@thatTypeAttr,@model.modelName)
      linkInstance.save()
      linkInstance

  # Remove an instance from the relation by removing its associated instance in the 
  # link model
  # @param [Mozart.Instance] instance The instance to remove from the relation
  remove: (instance) =>
    query = {}
    query[@thisFkAttr] = instance.id
    query[@thatFkAttr] = @record.id
    query[@thatTypeAttr] = @model.modelName
    for link in @linkModel.findByAttributes(query)
      link.destroy()

  # Query if the specified instance of the other model is in this relation by
  # checking for the existence of its link instance in the link model.
  # @param [Mozart.Instance] instance The instance to search for in the relation
  # @return [boolean] Returns true if the instance exists in the relation
  contains: (instance) =>
    query = {}
    query[@thisFkAttr] = instance.id
    query[@thatFkAttr] = @record.id
    query[@thatTypeAttr] = @model.modelName
    @linkModel.findByAttributes(query).length != 0

  # Called when a change happens on the link model, publish change on this relation.
  # @param [Mozart.Instance] link The link instance that changed
  # @private
  onModelChange: (link) =>
    if link[@thatFkAttr] == @record.id && link[@thatTypeAttr] == @model.modelName
      instance = @model.findById(link[@thisFkAttr])
      @publish('change', instance)

  # Release this relation instance, unsubscribing from all events on the link model.
  release: =>
    @unsubscribeEvents([@linkModel])
    super

exports.ManyToManyPolyReverseCollection = ManyToManyPolyReverseCollection