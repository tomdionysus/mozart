{View} = require './view'
Util = require './util'

exports.DynamicView = class DynamicView extends View
	
  skipTemplate: true

  init: =>
    super
    Util.log('dynamicview','init')
    
    @bind('change:schema', @afterRender) if @schema?

  afterRender: =>
    @releaseChildren()
    @element.empty()

    unless Util.isArray(@schema)
      Util.warn "DynamicView #{id}: schema is not an array"
      return

    for item in @schema
      if item.viewClass?
        @createView(item)
      else
        @createText(item)

  createView: (item) =>
    viewClass = Util._getPath(item.viewClass)

    # unless viewClass instanceof View
    #   Util.warn "DynamicView #{@id}: '#{item.viewClass}' is not a valid View class (#{viewClass})"
    #   return

    delete item.viewClass
    item.parent = @

    view = @layout.createView viewClass, item
    @element.append(view.createElement())
    @addView(view)
    @layout.queueRenderView(view)

  createText: (item) =>
    @element.append(item)
