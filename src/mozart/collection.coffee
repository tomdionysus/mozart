{View} = require './view'
Util = require './util'

exports.Collection = class Collection extends View

  tag: 'ul'
  skipTemplate: true

  # Initialize the collection View
  init: =>
    super
    Util.log('collection','init')
    @itemViews = {}

    @localMozartModel = Util._getPath('Mozart.Model')
    @localMozartInstanceCollection = Util._getPath('Mozart.InstanceCollection')

    if @filterAttribute?
      @bind('change:filterAttribute', @draw)
      @bind('change:filterText', @draw)

    if @sortAttribute?
      @bind('change:sortAttribute', @draw)
      @bind('change:sortDescending', @draw)

    @set("pageSize",10000) unless @pageSize?
    @set("pageCurrent",0) unless @pageCurrent?

    @bind('change:pageSize', @draw)
    @bind('change:pageCurrent', @draw)

    @method ?= 'all'
    
    @bind('change:collection', @afterRender)
    @bind('change:method', @afterRender)
    @collection.bind?('change', @afterRender)
      
  release: =>
    @collection.unbind?('change', @afterRender)
    super

  afterRender: =>
    @refresh()
    @draw()

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
          @dataSet[item.id] = item for item in @collecton[@method]()
      else if Util.isFunction(@collection)
        # Function that returns an array
        @dataSet[item.id] = item for item in @collection()
      else if Util.isArray(@collection)
        # Is an Array
        @dataSet[item.id] = item for item in @collection
      else 
        console.error("Collection: #{typeof @collection} can't be iterated")

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
  # @param instance [Mozart.DataInstance] The content for the new view
  createView: (instance) =>
    Util.log('collection','createView', instance,'layout',@layout.rootElement)

    obj = 
      content: instance
      parent: @
      
    obj.tag = 'li' if @viewClass == View
    obj.templateName = @viewClassTemplateName if @viewClassTemplateName?
    obj.templateFunction = @viewClassTemplateFunction if @viewClassTemplateFunction?
    obj.tag = @collectionTag if @collectionTag?
    obj.classNames = @collectionClassNames if @collectionClassNames?
    obj.tooltips = @tooltips if @tooltips?
    view = @layout.createView @viewClass,obj
    @element.append(view.createElement())
    @itemViews[instance.id] = view
    @addView(view)
    @layout.queueRenderView(view)
    
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
          @hidden[item.id] = 1 if hide 

    # Draw
    start = @pageCurrent * @pageSize
    count = 0
    vcount = 0
    dcount = 0
    for item in @displayOrder
      unless @hidden[item.id]?
        unless count<start or dcount>=@pageSize 
          unless @itemViews[item.id]?
            @createView(item) 
          @element.append(@itemViews[item.id].element)
          dcount++
        vcount++
      count++
    @set("pageTotal", Math.ceil(vcount/@pageSize))
    
    @set("pageCurrent", @pageTotal-1) if @pageCurrent > @pageTotal

exports.BoundView = class BoundView extends View

  init: ->
    super
    @content.bind 'change', @redraw

  release: ->
    @content.unbind 'change', @redraw
    super
