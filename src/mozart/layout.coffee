Util = require './util'
{Router} = require './router'

# Layout is responsible for rendering views onto an element according to a Route
# and maintaining route state. Each large section of a Mozart app that responds to 
# routes should have its own layout, and all layouts should be registered with the
# DOMManager.
exports.Layout = class Layout extends Router
  
  # Initiaise the Layout, checking and registering all states (routes)
  init: =>
    super

    Util.warn 'Layout must have states',@ unless @states?
    Util.warn 'Layout must have a rootElement selector',@ unless @rootElement?

    @viewRenderQueue = []
    @releaseMap = {}
    @views = {}
    @currentState = null
    @controls = {}
    @hasClickOutside = {}
    @hasClickInside = {}

    for state in @states when state.path? and state.viewClass?
      @register(state.path, @doRoute, state)

  # Create a view in this layout, registering clickInside and clickOutside if
  # defined on the view
  # @param [Mozart.View] viewClass The class of the view to instantiate
  # @param [object] options The map of options to pass to the viewClass create
  createView: (viewClass, options = {}) =>
    options.layout = @
    view = viewClass.create options
    @views[view.id] = view
    @hasClickInside[view.id] = view if view.clickInside?
    @hasClickOutside[view.id] = view if view.clickOutside?
    view

  # Bind the DOM element selected by rootElement to be the target for this 
  # Layout.
  bindRoot: =>
    @rootEl = $(@rootElement)[0]
    Util.warn 'Layout cannot find any elements for rootElement selector',@ unless @rootEl?

  # Reset the current route to no route and relase all views.
  resetRoute: =>
    @viewRenderQueue = []
    @currentState = null
    @releaseViews()

  # Attempt to transition to the specified state (route), using route arguments
  # @param [Mozart.Route] state The route to transition to
  # @param [object] params The arguments parsed from the route path
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

  # Perform the transition to the specified state (route), creating the route view 
  # and queueing the previous view (if any) for release.
  # @param [Mozart.Route] state The route to transition to
  _transition: (state) =>
    @resetRoute()
    @currentState = state
    @currentState.doTitle()
    
    if @currentState.viewClass?
      @queueReleaseView(@currentView) if @currentView?
      @currentView = @createView(@currentState.viewClass, @currentState.viewOptions)
      @currentView.el = @rootEl
      @queueRenderView(@currentView)

  # Queue the specified view instance to be rendered.
  # @view [Mozart.View] state The view to render
  queueRenderView: (view) =>
    Util.log('layout',"#{@_mozartId} queueRenderView", view)
    @views[view.id] ?= view

    _.delay(@processRenderQueue,0) if @viewRenderQueue.length==0
    @viewRenderQueue.push(view)

  # Process the render queue, preparing content, assigning elements, swapping elements, and
  # calling postRender on each view.
  #
  # For more information, see http://www.mozart.io/guides/understanding_rendering
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

  # Release this layout, releasing all created views
  release: =>
    @releaseViews()
    super

  # Queue a view for release.
  # @param [Mozart.View] view The view to queue for release
  queueReleaseView: (view) =>
    @releaseMap[view.id] = view

  releaseView: (view) =>
    @releaseViewControls(view)
    delete @views[view.id]
    delete @hasClickOutside[view.id]
    delete @hasClickInside[view.id]

  # Release all views in this layout
  releaseViews: =>
    for id, view of @views
      Util.log('layout',"processRenderQueue:releasing",view.id, view)
      @queueReleaseView(view)
      @processRenderQueue()

  # Add a control with the specified id and control
  # @param [string] id The id of the control
  # @param [Mozart.Control] control The control view
  addControl: (id, control) =>
    Util.log('layout','adding control', id, control)
    @controls[id] = control

  # Get the control with the specified id
  # @param [string] id The id of the control to get
  # @return [Mozart.Control] The control, or null if not found.
  getControl: (id) =>
    @controls[id]

  # Remove the control with the specified id
  # @param [string] id The id of the control to delete
  removeControl: (id) =>
    Util.log('layout','removing control', id)
    delete @controls[id]

  # Remove all controls for a specified view
  # @param [Mozart.View] view The view for which to remove all controls
  releaseViewControls: (view) =>
    for id, control of @controls when control.view == view
      Util.log('layout','releasing control for view', view, 'control', control.action, control)
      @removeControl(id)
        