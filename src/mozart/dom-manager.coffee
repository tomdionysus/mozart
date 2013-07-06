Util = require './util'
{MztObject} = require './object'

exports.DOMManager = class DOMManager extends MztObject

  viewEventMap = {
    click: 'click'
    dblclick: 'dblClick'
    focus: 'focus'
    blur: 'blur'
    keyup: 'keyUp'
    keydown: 'keyDown'
    keypress: 'keyPress'
    focusout: 'focusOut'
    focusin: 'focusIn'
    change: 'change'
    mouseover: 'mouseOver'
    mouseout: 'mouseOut'
  }

  init: ->
    @element = $(@rootElement)

    for domevent, method of viewEventMap
      @element.on(domevent, null, { eventName: method }, @onApplicationEvent)

    events = (i for i, v of viewEventMap).join(' ')

    @element.on(events, '[view]', @onViewEvent)
    @element.on(events, '[data-mozart-action]', @onControlEvent)

    @openElements = {}

  find: (id) =>
    for layout in @layouts
      if layout.views[id]?
        Util.log("general","#{id}: view of",layout.rootElement)
        return layout.views[id]
      control = layout.getControl(id)
      if control?
        Util.log("general","#{id}: control of",layout.rootElement)
        return control

    elements = $("##{id}")
    if elements.length > 0
      Util.log("general","#{id} is a an element")
      return elements[0]

    Util.log("general","Cannot find ID #{id}")

  checkClickInside: (event) =>
    return unless (event.type == 'click') 

    for layout in @layouts
      for id, view of layout.hasClickInside
        if $(event.target).parents('#'+id).length > 0
          Util.log('events','clickInside on', view,'(',event,')')
          view.clickInside()        

  checkClickOutside: (event) =>
    return unless (event.type == 'click') 

    for layout in @layouts
      for id, view of layout.hasClickOutside
        if $(event.target).parents('#'+id).length == 0
          Util.log('events','clickOutside on', view,'(',event,')')
          view.clickOutside()

  release: =>
    for domevent, method of viewEventMap
      @element.off(domevent, null, @_checkRootEvent)

    events = (i for i, v of viewEventMap).join(' ')

    @element.off(events, '[view]', @onViewEvent)
    @element.off(events, '[data-mozart-action]', @onControlEvent)
    super

  onApplicationEvent: (event) =>
    @publish event.data.eventName, event

  onViewEvent: (event) =>
    @checkClickInside(event)

    view = null
    ele = targetEle = event.currentTarget
    return unless ele?
      
    for layout in @layouts
      view = layout.views[ele.id]
      if view? 
        methodName = viewEventMap[event.type]
        @publish "viewEvent", event, view  
        if typeof (view[methodName]) == 'function'
          Util.log('events',methodName,'on',view,'(',event,')')
          view[methodName](event,view)

    @checkClickOutside(event)
    true

  onControlEvent: (event) =>
    @checkClickInside(event)

    ele = $(event.currentTarget)
    id = ele.attr('data-mozart-action')
    Util.log('controls','action', event)
    for layout in @layouts
      control = layout.getControl(id)

      if control?  && (control.events==null || (event.type in control.events))
        if typeof (control.view[control.action]) == 'function'
          Util.log 'events','method', control.action,'on',control.view,'(',event,')'
          Util.log 'controls','action on control', control, event
          @publish "controlEvent", event, control 
          control.view[control.action](ele, @getControlOptionsValues(control.view, control.options), event)
          event.preventDefault() unless control.allowDefault 
        else 
          Util.warn "Action #{control.action} does not exist on view #{control.view.id}, #{control.view.name}", control
    
    @checkClickOutside(event)

    event.stopImmediatePropagation()

  # Get a set of options for an action in a control, getting the values of *Lookup properties.
  getControlOptionsValues: (view, options) =>
    out = {}
    for k,v of options
      if Util.stringEndsWith(k,'Lookup')
        k2 = Util.sliceStringBefore(k,'Lookup')
        out[k2] = Util._getPath(view, v)
      else
        out[k]=v
    out