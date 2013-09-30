{View} = require './view'
Util = require './util'

# DynamicView is a View that will create a set of views depending on a supplied schema.
# The schema should be an array of strings or objects, with each object containing a 
# viewClass to instantiate.
#
# DynamicView is intended to ease generation of forms given a dynamic schema.
class DynamicView extends View
	
  skipTemplate: true

  # Initialise the DynamicView, checking for schema and subscribing to changes of
  # the schema.
  init: =>
    super
    Util.warn 'DynamicView needs a schema', @ unless @schema?
    
    @subscribe('change:schema', @afterRender)

  # After render, create and append all views and text from the schmea.
  afterRender: =>
    @releaseChildren()
    @element.empty()

    unless Util.isArray(@schema)
      Util.warn "DynamicView schema is not an array", @
      return

    for item in @schema
      if item.viewClass?
        @createView(item)
      else
        @createText(item)

  # Create a view from the supplied item.
  # @param item [object] An object containing a viewClass property, which should be the string path of the View class to instantiate, e.g. 'App.SomeItemView'
  createView: (item) =>
    viewClass = Util._getPath(item.viewClass)

    delete item.viewClass
    item.parent = @

    view = @layout.createView viewClass, item
    @element.append(view.createElement())
    @addView(view)
    @layout.queueRenderView(view)

  # Create text from an item
  # @param item [string] The text to append. 
  createText: (item) =>
    @element.append(item)

exports.DynamicView = DynamicView
