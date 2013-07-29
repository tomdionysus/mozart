Util = require './util'
{Router} = require './router'

exports.Layout = class Layout extends Router
  
  init: =>
    super

    @viewRenderQueue = []
    @releaseMap = {}
    @views = {}
    @currentState = null
    @controls = {}
    @hasClickOutside = {}
    @hasClickInside = {}

    for state in @states when state.path? and state.viewClass?
      @register(state.path, @doRoute, state)

  createView: (viewClass, options = {}) =>
    options.layout = @
    view = viewClass.create options
    @views[view.id] = view
    @hasClickInside[view.id] = view if view.clickInside?
    @hasClickOutside[view.id] = view if view.clickOutside?
    view

  bindRoot: =>
    @rootEl = $(@rootElement)[0]

  resetRoute: =>
    @viewRenderQueue = []
    @currentState = null
    @releaseViews()

  doRoute: (state, params) =>
    if (@currentState? and not @currentState.canExit())
      Util.log('layout', 'cannot exit state', @currentState)
      return false
    @currentState = null
    unless state.canEnter(params)
      Util.log('layout', 'cannot enter state', state, params)
      return false
    @_transition(state)
    true

  _transition: (state) =>
    @resetRoute()
    @currentState = state
    @currentState.doTitle()
    
    if @currentState.viewClass?
      @releaseMap[@currentView.id] = @currentView if @currentView?
      @currentView = @createView(@currentState.viewClass, @currentState.viewOptions)
      @currentView.el = @rootEl
      @queueRenderView(@currentView)

  queueRenderView: (view) =>
    Util.log('layout',"#{@_mozartId} queueRenderView", view)
    @views[view.id] ?= view

    @scheduleProcessRenderQueue() if @viewRenderQueue.length==0
    
    @viewRenderQueue.push(view)

  scheduleProcessRenderQueue: =>
    func = window.webkitRequestAnimationFrame ||
    window.mozRequestAnimationFrame ||
    window.oRequestAnimationFrame ||
    window.msRequestAnimationFrame

    if func?
      func(@processRenderQueue)
    else
      _.delay(@processRenderQueue,0)

  processRenderQueue: =>
    return if @released

    return if @viewRenderQueue.length is 0 
    Util.log('layout',"#{@_mozartId} processRenderQueue with #{@viewRenderQueue.length} views")

    postRenderQueue = []
    renderQueue = []

    # Prepare all content
    while @viewRenderQueue.length > 0
      view = @viewRenderQueue.shift()
      view.beforeRender()
      view.releaseChildren()
      view.prepareElement()
      renderQueue.push(view)

    # Find Set of top level elements
    toRemove = []

    for view1 in renderQueue
      for view2 in renderQueue when view2!=view1
        toRemove.push(view1) if view1.hasAncestor(view2) and !_.contains(toRemove,view1)

    topRenderQueue = _.difference(renderQueue,toRemove)

    # Assign real Elements
    for view in topRenderQueue
      view.reassignElements()

    # Swap Elements
    for view in topRenderQueue
      view.replaceElement()

    # Post Render
    for view in renderQueue
      view.postRender()

    # Process release queue
    for id, view of @releaseMap
      view.release() if view?
    @releaseMap = {}

    Util.log('layout',"#{@_mozartId} render finished")
    @publish 'render:complete'

  release: =>
    @releaseViews()
    super

  queueReleaseView: (view) =>
    @releaseMap[view.id] = view

  releaseView: (view) =>
    @releaseViewControls(view)
    delete @views[view.id]
    delete @hasClickOutside[view.id]
    delete @hasClickInside[view.id]

  releaseViews: =>
    for id, view of @views
      Util.log('layout',"processRenderQueue:releasing",view.id, view)
      @releaseMap[id] = view
      @processRenderQueue()

  addControl: (id, control) =>
    Util.log('layout','adding control', id, control)
    @controls[id] = control

  getControl: (id) =>
    @controls[id]

  removeControl: (id) =>
    Util.log('layout','removing control', id)
    delete @controls[id]

  releaseViewControls: (view) =>
    for id, control of @controls when control.view == view
      Util.log('layout','releasing control for view', view, 'control', control.action, control)
      delete @controls[id]
        