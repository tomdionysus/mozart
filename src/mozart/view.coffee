{MztObject} = require './object'
Util = require './util'

exports.View = class View extends MztObject

  tag: 'div'
  disableHtmlAttributes: false
  disableAutoActions: false
  idPrefix: 'view'

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
      unless @templateName?
        Util.error 'View: View has no templateName or templateFunction',"view",@
      @templateFunction = HandlebarsTemplates[@templateName]

    Util.log('views',"view #{@id} init")

    @subscribe('change:display', @redraw)

    @createAutoActions() unless @disableAutoActions
    @createHtmlAttrBindings() unless @disableHtmlAttributes

  prepareElement: =>
    return if @released
    @newElement = @createElement()
    @newElement.innerHTML = @templateFunction(@,{data:@}) if not @skipTemplate and @display

  reassignElements: =>
    for id, view of @childViews
      view.reassignElements()

    if @parent?
      @el = @parent.findElementInPreparedContent(@id)  

  findElementInPreparedContent: (id) =>
    return null unless @newElement
    x = @_find(@newElement,id)
    x

  _find: (ele,id) ->
    return ele if ele.id == id
    for e in ele.children
      x = @_find(e,id)
      return x if x?

    return null

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
   
  beforeRender: ->

  afterRender: ->

  # postRender is called by the view manager after ALL views have been rendered.
  postRender: =>
    return if @released
    @createDomBinds()
    @afterRender()

  redraw: =>
    return if @released
    @layout.queueRenderView(@)

  addView: (view) =>
    @childViews[view.id] = view
    @namedChildViews[view.name] = view if view.name?

  childView: (name) =>
    @namedChildViews[name]

  namedChildViewExists: (name) =>
    @namedChildViews[name]?

  releaseChildren: ->
    for id, view of @childViews
      @layout.queueReleaseView view

    @childViews = {}
    @namedChildViews = {}

  removeView: (view) =>
    delete @childViews[view.id] if @childViews?

  hasAncestor: (view) =>
    p = @parent
    while p?
      return true if p.id == view.id
      p = p.parent
    false

  release: =>
    return if @released
    Util.log('views',@layout,"releasing view #{@id}")
    @removeDomBinds()
    @parent.removeView(@) if @parent?
    @releaseChildren()
    @element.remove() if @element?
    @layout.releaseView(@)
    super

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

  getHtmlAttrsMap: =>
    map = {}
    for k,v of @ when typeof(@[k]) == 'string' and Util.stringEndsWith(k, 'Html')
      map[Util.sliceStringBefore(k, 'Html')] = v
    map

  copyHtmlAttrsToElement: (element) =>
    element.attr(@getHtmlAttrsMap())
    element

  registerDomBind: (bindId, target) ->
    [path, attr] = Util.parsePath(target)
    if path?
      obj = Util.getPath(@, path)
    else
      obj = @
    
    Util.error "View.registerDomBind (bind helper) - cannot find object #{path}" unless obj?
    @domBindings[bindId] = { view: @, target: obj, attribute:attr, element:null }

  createDomBinds: ->
    for bindId, binding of @domBindings
      binding.element = $("#"+bindId)
      Util.error "View.createDomBinds - cannot find element #{bindId}" unless binding.element?
      binding.target.subscribe 'change:'+binding.attribute, @onDomBindChange, binding
      binding.element.text(binding.target[binding.attribute])

  onDomBindChange: (triggerdata,binding) ->
    binding.element.text(binding.target[binding.attribute])

  removeDomBinds: ->
    for bindId, binding of @domBindings when binding.element is not null
      binding.target.unsubscribe 'change:'+binding.attribute, @onDomBindChange
    @domBindings = {}

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

  createHtmlAttrBindings: =>
    for k,v of @getHtmlAttrsMap()
      @subscribe 'change:'+k+"Html", =>
        return unless @element?
        @element.attr(k, @[k+'Html'])

