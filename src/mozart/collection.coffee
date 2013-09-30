{View} = require './view'
Util = require './util'

# Collection is the the view class for the Mozart collection handlebars helper - a view
# that renders a collection of other views, one for each data item in its collection property.
#
# The collection property can be:
# * A Mozart Model
# * A Mozart Relation object
# * An Array of objects
#
# If an array is supplied, collection expects an array of objects, each of which must have a 
# at least one unique property, specified by @idField.
#
# For more information, see http://mozart.io/collection_demo
class Collection extends View

  # The default tag for a collection is 'ul'
  tag: 'ul'

  # Collections do not have a template
  skipTemplate: true

  # The field to use as a unique identifier, default 'id'
  idField: 'id'

  # Set up the collection, detecting the collection type, setting up filters, sorts, paging
  # and subscribing 
  init: =>
    super
    Util.log('collection','init')
    @itemViews = {}

    @localMozartModel = Util._getPath('Mozart.Model')
    @localMozartInstanceCollection = Util._getPath('Mozart.InstanceCollection')

    if @filterAttribute?
      @subscribe('change:filterAttribute', @draw)
      @subscribe('change:filterText', @draw)

    if @sortAttribute?
      @subscribe('change:sortAttribute', @draw)
      @subscribe('change:sortDescending', @draw)

    @set("pageSize",10000) unless @pageSize?
    @set("pageCurrent",0) unless @pageCurrent?

    @subscribe('change:pageSize', @draw)
    @subscribe('change:pageCurrent', @draw)

    @method ?= 'all'
    @displayWhenEmpty ?= true
    
    @subscribe('change:collection', @afterRender)
    @subscribe('change:method', @afterRender)
    @collection.subscribe?('change', @afterRender)
  
  # Release the collection view, unsubscribing from collection changes if supported.
  release: =>
    @collection.unsubscribe?('change', @afterRender)
    super

  # Refresh the data and sync the view contents
  afterRender: =>
    @refresh()
    @draw()

  # Refresh the data from the collection, creating and destroying item views as required.
  refresh: =>
    Util.log('collection','refresh')

    @dataSet = {}

    if @collection?

      if Util.isObject(@collection)
        # Object
        if Util.isFunction(@collection[@method+"AsMap"])
          # ..that has a <all>AsMap function
          @dataSet = @collection[@method+"AsMap"]()
        else if Util.isFunction(@collection[@method])
          # ..that has a <all> function
          @dataSet[item[@idField]] = item for item in @collecton[@method]()
      else if Util.isFunction(@collection)
        # Function that returns an array
        @dataSet[item[@idField]] = item for item in @collection()
      else if Util.isArray(@collection)
        # Is an Array
        @dataSet[item[@idField]] = item for item in @collection
      else 
        Util.error("Collection: #{typeof @collection} can't be iterated")

    toDestroy = []
    for id, view of @itemViews
      unless @dataSet[id]?
        toDestroy.push(id)

    while toDestroy.length > 0
      id = toDestroy.pop()
      Util.log('collection','destroyView', id, @itemViews[id])
      @removeView(@itemViews[id])
      @itemViews[id].element?.remove()
      @layout.queueReleaseView(@itemViews[id])
      delete @itemViews[id]

  # Create a View for a data item
  #
  # @param instance [Mozart.Instance] The content for the new view
  createView: (instance) =>
    Util.log('collection','createView', instance,'layout',@layout.rootElement)

    obj = 
      content: instance
      parent: @

    obj.tag = 'li' if @viewClass == View

    obj.templateName = @viewClassTemplateName
    obj.templateFunction = @viewClassTemplateFunction
    obj.tag = @collectionTag
    obj.classNames = @collectionClassNames
    obj.tooltips = @tooltips
    view = @layout.createView @viewClass,obj
    @element.append(view.createElement())
    @itemViews[instance[@idField]] = view
    @addView(view)
    @layout.queueRenderView(view)
    
  # Detach all views and reinsert them according to the current filter and sort.
  draw: =>
    #Detach All
    for id, view of @itemViews
      view.element?.detach()

    @displayOrder = _(@dataSet).values()
    @hidden = {}

    # Sort
    Util.sortBy(@displayOrder, @sortAttribute) if @sortAttribute?
    @displayOrder.reverse() if @sortDescending

    # Filter
    if @filterText? and @filterAttribute? and @filterText.length>0
      st = @filterText.toString().toLowerCase()
      for item in @displayOrder
        hide = true
        for field in @filterAttribute.split(',')
          vl = Util.getPath(item, field)
          hide = hide and (vl.toString().toLowerCase().indexOf(st) == -1) if vl?
          @hidden[item[@idField]] = 1 if hide 

    # Empty?
    unless @displayWhenEmpty
      @set 'display', @displayOrder.length != 0
      return unless @display

    # Draw
    start = @pageCurrent * @pageSize
    count = 0
    rows = 0
    page = 0
    for item in @displayOrder
      unless @hidden[item[@idField]]?
        unless count<start or page>=@pageSize
          @createView(item) unless @itemViews[item.id]?
          @element.append(@itemViews[item[@idField]].element)
          page++
        @itemViews[item.id].set('order',{total: @displayOrder.length, position:rows})
        rows++
      count++
    @set("pageTotal", Math.ceil(rows/@pageSize))

    @set("pageCurrent", @pageTotal-1) if @pageCurrent > @pageTotal

# BoundView is a View that watches for changes on its content property and redraws
# itself with every change.
class BoundView extends View

  # Initialise the BoundView and subscribe to changes on content.
  init: ->
    super
    @content.subscribe 'change', @redraw

  # Release the BoundView and unsubscribe to changes on content.
  release: ->
    @content.unsubscribe 'change', @redraw
    super

exports.Collection = Collection
exports.BoundView = BoundView
