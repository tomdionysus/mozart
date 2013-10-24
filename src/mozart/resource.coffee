{MztObject} = require './object'
Util = require './util'

# Resource is the base class for Mozart Resources, and are used when working with REST resources 
# that don't have a 1-to-1 mapping with individual models, and where complex loading and saving 
# logic exists, by encapsulating the required AJAX and mapping code.
#
# Resources should be implemented by extending Resource.
#
# @example Example Cats Resource
#   class App.CatsResource extends Mozart.Resource
#
#     resource: "/cats"
#     model: Cohort.Cat
#     serverIdField: 'id'
#     clientApiField: 'api_id'
#
#     mapServerData: (data) ->
#       api_id: data[@serverIdField]
#       name: data.name
#
#     mapClientData: (instance) ->
#       name: instance.name
#
# @example Mapping API foreign keys
#
#     mapServerData: (data) ->
#       api_id: data.id
#       name: data.name
#       house_id: @getForeignKey(App.House, data.house_id, 'api_id', 'id')
#
#     mapClientData: (instance) ->
#       name: instance.name
#       house_id: @getForeignKey(App.House, instance.house_id, 'id', 'api_id')
#
class Resource extends MztObject

  # Initialise the resource, checking for existence of required defaults and methods.
  init: =>
    Util.error 'Resource: Resource has no url', @ unless @url? and @url.length>0
    Util.error 'Resource: Resource has no serverIdField', @ unless @serverIdField? and @serverIdField.length>0
    Util.error 'Resource: Resource has no clientApiField', @ unless @clientApiField? and @clientApiField.length>0
    Util.error 'Resource: Resource has no model', @ unless @model?
    Util.error 'Resource: Resource must define mapServerData method', @ unless @mapServerData? and Mozart.isFunction(@mapServerData)
    Util.error 'Resource: Resource must define mapClientData method', @ unless @mapClientData? and Mozart.isFunction(@mapClientData)

    @http = Mozart.HTTP.create()

    @model.subscribe 'create', @create
    @model.subscribe 'update', @update
    @model.subscribe 'destroy', @destroy

  # Load all records from the resource into the model, creating or updating as required, using GET.
  # @param [function] callback (optional) The success callback
  # @param [function] error_callback (optional) The error callback
  loadAll: (callback, error_callback) =>
    @http.get @url,
      callbacks:
        success: (args...) =>
          @loadAllSuccess(args...)
          callback?()
        error: (args...) =>
          error_callback?(args...)

  # loadAllSuccess is called when the AJAX request from loadAll succeeds.
  # @param [array] data An array of server objects to create or update.
  loadAllSuccess: (data) =>
    @createOrUpdateFrom(item) for item in data

  # Load the record with the specified serverId from the resource into the model using GET.
  # Like loadAll, load will create or update the instance as required.
  # @param [string] serverId The server Id or resource identifier
  # @param [function] callback (optional) The success callback
  # @param [function] error_callback (optional) The error callback
  load: (serverId, callback, error_callback) =>
    @http.get @url+'/'+serverId,
      callbacks:
        success: (args...) =>
          @loadSuccess(args...)
          callback?(args...)
        error: (args...) =>
          error_callback?(args...)

  # loadSuccess is called when the AJAX request from load succeeds.
  # @param [object] data The data returned by the request
  loadSuccess: (data) =>
    @createOrUpdateFrom(data)

  # If the server object supplied has a corresponding instance, find
  # and update that instance, or create an instance with the server data.
  # @param [object] data A server object to create or update.
  createOrUpdateFrom: (data) =>
    citems = @model.findByAttribute(@clientApiField,data[@serverIdField])
    unless citems.length>0
      @model.createFromValues @mapServerData(data)
    else
      citems[0].copyFrom @mapServerData(data)

  # Create a resource record from the specified instance by issuing a POST.
  # The instance will have its clientApiField update with the server identifier on success.
  # @param [Mozart.Instance] instance The instance to create in the POST.
  # @param [function] callback (optional) The success callback
  # @param [function] error_callback (optional) The error callback
  create: (instance, callback, error_callback) =>
    return if instance[@clientApiField]?
    @http.post @url,
      data: JSON.stringify(@mapClientData(instance))
      callbacks:
        success: (data) =>
          @createSuccess(data, instance)
          callback?(data, instance) 
        error: (args...) =>
          error_callback?(args...)

  # createSuccess is called when the AJAX request from create succeeds.
  # @param [object] data The data returned by the request
  # @param [ozart.Instance] instance The original instance that was POSTed.
  createSuccess: (data, instance) =>
    instance.set(@clientApiField, data[@serverIdField])

  # Update a resource record from the specified instance by issuing a PUT.
  # @param [Mozart.Instance] instance The instance to update in the PUT.
  # @param [function] callback (optional) The success callback
  # @param [function] error_callback (optional) The error callback
  update: (instance, callback, error_callback)  =>
    return unless instance[@clientApiField]?
    @http.put @url+'/'+instance[@clientApiField],
      data: JSON.stringify(@mapClientData(instance))
      callbacks:
        success: (data) =>
          @updateSuccess(data, instance)
          callback?(data, instance) 
        error: (args...) =>
          error_callback?(args...)

  # updateSuccess is called when the AJAX request from update succeeds.
  # @param [object] data The data returned by the request
  # @param [ozart.Instance] instance The original instance that was POSTed.
  updateSuccess: (data, instance) =>
    
  # Destroy the resource record of the specified instance by issuing a DELETE.
  # @param [Mozart.Instance] instance The instance to destroy in the DELETE.
  # @param [function] callback (optional) The success callback
  # @param [function] error_callback (optional) The error callback
  destroy: (instance, callback, error_callback)  =>
    return unless instance[@clientApiField]?
    @http.delete @url+'/'+instance[@clientApiField],
      callbacks:
        success: (data) =>
          @destroySuccess(data, instance)
          callback?(data, instance)
        error: (args...) =>
          error_callback?(args...)

  # destroySuccess is called when the AJAX request from destroy succeeds.
  # @param [object] data The data returned by the request
  # @param [Mozart.Instance] instance The original instance that was POSTed.
  destroySuccess: (data, instance) =>

  # A helper method to lookup client or server ids on another model, used
  # to map foreign keys in mapClientData and mapServerData
  # @param [Mozart.Model] model The model on which to perform the lookup
  # @param [string] client_id The value to lookup on the client
  # @param [string] clientIdField The field in which to look up the client_id
  # @param [string] serverIdField The field to return
  # @return [variant] The value of the serverIdField in the found instance, or null.
  getForeignKey: (model, client_id, clientIdField, serverIdField) ->
    lst = model.findByAttribute(clientIdField,client_id)
    return null if lst.length == 0
    lst[0][serverIdField]

exports.Resource = Resource
