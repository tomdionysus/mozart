{MztObject} = require './object'
Util = require './util'

# View is both the default View class and the base class for all Views in Mozart.
class View extends MztObject

  tag: 'div'
  disableHtmlAttributes: false
  disableAutoActions: false
  idPrefix: 'view'

  # Initialise the View
  init: =>
    @id ?= "#{@idPrefix}-"+@_mozartId
    @childViews = {}
    @context ?= {}
    @namedChildViews = {}
    @valid = true
    @domBindings = {}
    @display ?= true

    @parent.addView(@) if @parent?

    unless @templateFunction? or @skipTemplate?
      Util.error 'View: View has no templateName or templateFunction',"view",@ unless @templateName?
      Util.error "View: Template '#{@templateName}' does not exist in window.HandlebarsTemplates","view",@ unless HandlebarsTemplates[@templateName]?
      @templateFunction = HandlebarsTemplates[@templateName]

    Util.log('views',"view #{@id} init")

    @subscribe('change:display', @redraw)

    @createAutoActions() unless @disableAutoActions
    @createHtmlAttrBindings() unless @disableHtmlAttributes

  # Prepare the newElement by creating it
  prepareElement: =>
    return if @released
    @newElement = @createElement()
    @newElement.innerHTML = @templateFunction(@,{data:@}) if not @skipTemplate and @display

  # Reassign all child view elements, and find this view's element in its parent's newElement
  # if it isn't a root view.
  reassignElements: =>
    for id, view of @childViews
      view.reassignElements()

    if @parent?
      @el = @parent.findElementInPreparedContent(@id)  

  # Find the element with the specified id in the prepared content (newElement)
  findElementInPreparedContent: (id) =>
    return null unless @newElement
    x = @_find(@newElement,id)
    x

  # Find the element with the specified id in another element, even if it is not currently
  # on the DOM.
  # @param [DOMElement] ele The element in which to search
  # @param [string] id The id to search for
  # @return [DOMElement] The element with the corresponding id, or NULL if not found.
  # @private
  _find: (ele,id) ->
    return ele if ele.id == id
    for e in ele.children
      x = @_find(e,id)
      return x if x?

    return null

  # Call replaceElement on all child views and replace the current element in this view's
  # parent with the prepared content (newElement) if this view is not a root view.
  replaceElement: =>
    return if @released
    return unless @el

    for id, view of @childViews
      view.replaceElement()

    unless @el == @newElement
      @oldEl = @el
      @el.parentNode.replaceChild @newElement, @el
      if @layout? && @el == @layout.rootEl
        @layout.rootEl = @newElement
      @el = @newElement
      delete @oldEl
    @element = $(@el)
   
  # Called before rendering, beforeRender should be overridden with a function containing
  # any code required to run just before the view is rendered, if required.
  beforeRender: ->

  # Called by postRender, afterRender should be overridden with a function containing
  # any code required to run after the view is rendered, if required.
  # afterRender is called after all views in the current render queue, including this 
  # view's children, have been rendered
  afterRender: ->

  # postRender is called by the layout after ALL views have been rendered.
  #
  # Do not override postRender. Override afterRender in your View class to run view code
  # after rendering.
  postRender: =>
    return if @released
    @createDomBinds()
    @afterRender()

  # Redraw the current view by queueing it for rendering with the layout.
  redraw: =>
    return if @released
    @layout.queueRenderView(@)

  # Add an existing view to this view as a child.
  # @param [Mozart.View] view The view to add as a child
  addView: (view) =>
    @childViews[view.id] = view
    @namedChildViews[view.name] = view if view.name?

  # Return a named child view given its name
  # @param [string] name The name of the named child view
  # @return [Mozart.View] The view with the specified name, or NULL if not found.
  childView: (name) =>
    @namedChildViews[name]

  # Find if a named child view exists
  # @param [string] name The name of the child view
  # @return [boolean] Return true if this view has a child view with the supplied name
  namedChildViewExists: (name) =>
    @namedChildViews[name]?

  # Release all child views of this view by queueing them for removal with the layout.
  releaseChildren: ->
    for id, view of @childViews
      @layout.queueReleaseView view

    @childViews = {}
    @namedChildViews = {}

  # Remove a specified view from this view's children.
  # This does not release the child view.
  # @param [Mozart.View] view The view to remove from this view's children.
  removeView: (view) =>
    delete @childViews[view.id] if @childViews?

  # Find if this view has the specified view as an ancestor. This will search all
  # views up to the containing layout.
  # @param [Mozart.View] view The ancestor view to check for
  # @return [boolean] Return true if this view has the specified ancestor. 
  hasAncestor: (view) =>
    p = @parent
    while p?
      return true if p.id == view.id
      p = p.parent
    false

  # Release this view: remove all DOM bindings, remove it from its parent's
  # children (if this view is not a layout level view), release all its children, remove 
  # its element from the DOM if this view is currently rendered, and calling releaseView 
  # on its layout.
  release: =>
    return if @released
    Util.log('views',@layout,"releasing view #{@id}")
    @removeDomBinds()
    @parent.removeView(@) if @parent?
    @releaseChildren()
    @element.remove() if @element?
    @layout.releaseView(@)
    super

  # Create a DOM element for this view off-DOM with the current state of
  # the display, id, tag and the set of *Html attributes, and return that
  # element.
  # @return [DOMElement] The new element
  createElement: =>
    if @display == false
      element = document.createElement("script")
      element.setAttribute('id',@id)
      return element
    element = document.createElement(@tag)
    element.setAttribute('id',@id)
    element.setAttribute('view','')
    unless @disableHtmlAttributes
      for k,v of @getHtmlAttrsMap()
        element.setAttribute(k,v) 
    element

  # Get all *Html attributes as a map. This will return an object with the attribute
  # names, stripped of the HTML suffix, and their values.
  # @return [object] A map of attribute names and values.
  getHtmlAttrsMap: =>
    map = {}
    for k,v of @ when typeof(@[k]) == 'string' and Util.stringEndsWith(k, 'Html')
      map[Util.sliceStringBefore(k, 'Html')] = v
    map

  # Copy all *Html attributes and values to the specified element.
  # @param [jQueryElement] element The element to set attributes on
  # @return [jQueryElement] The specified element
  copyHtmlAttrsToElement: (element) =>
    element.attr(@getHtmlAttrsMap())
    element

  # Register a DOM binding with the specified id and target (path)
  # @param [string] bindId The id of the binding
  # @param [string] target The application path to bind to
  registerDomBind: (bindId, target) ->
    [path, attr] = Util.parsePath(target)
    if path?
      obj = Util.getPath(@, path)
    else
      obj = @
    
    Util.error "View.registerDomBind (bind helper) - cannot find object #{path}" unless obj?
    @domBindings[bindId] = { view: @, target: obj, attribute:attr, element:null }

  # Create all registered DOM bindings for this view by subscribing to changes on each path
  # and setting the element text to the current value of the bound property.
  createDomBinds: ->
    for bindId, binding of @domBindings
      binding.element = $("#"+bindId)
      Util.error "View.createDomBinds - cannot find element #{bindId}" unless binding.element?
      binding.target.subscribe 'change:'+binding.attribute, @onDomBindChange, binding
      binding.element.text(binding.target[binding.attribute])

  # Called when the change event of a bound property is published, set the element text to 
  # the current value of the bound property.
  # @param [void] triggerdata The data from the publish call, unused by this function
  # @param [object] binding The binding as registered
  onDomBindChange: (triggerdata,binding) ->
    binding.element.text(binding.target[binding.attribute])

  # Remove all DOM bindings by unsubscribing from changes on each path
  removeDomBinds: ->
    for bindId, binding of @domBindings when binding.element is not null
      binding.target.unsubscribe 'change:'+binding.attribute, @onDomBindChange
    @domBindings = {}

  # Create automatic actions by parsing all *Action attributes.
  createAutoActions: =>
    for key, value of @ when Mozart.isString(key) and Mozart.stringEndsWith(key,'Action')

      [target, method] = Mozart.parsePath(value)
      if target?
        target = Mozart.getPath(@parent,target)
      else
        target = @parent

      actionName = Mozart.sliceStringBefore(key, 'Action')
      @subscribe(actionName, (args) => 
        target[method](@,args,actionName)
      )

  # Create HTML attribute bindings by subscribing to changes on each *Html property of
  # this view instance with a callback to set the associated attribute on this view's
  # element.
  createHtmlAttrBindings: =>
    for k,v of @getHtmlAttrsMap()
      @subscribe 'change:'+k+"Html", =>
        return unless @element?
        @element.attr(k, @[k+'Html'])

exports.View = View

