Util = require './util'
{MztObject} = require './object'

# DOMManager manages DOM interactions for the whole Mozart application. There should
# be a maxiumum of one DOMManager per Mozart application.
#
# It is responsible for routing DOM events to interested views, handling the action
# handlebars helper and the abstract clickInside/clickOutside events.
class DOMManager extends MztObject

  # A map of DOM event names to view method names.
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

  # Initialise the DOMManager, checking and finding the rootElement and binding to
  # all configured DOM events in viewEventMap, all view events, and all view actions
  # on that element.
  init: ->
    Util.warn "DOMManager must have a rootElement",@ unless @rootElement
    @element = $(@rootElement)

    Util.warn "DOMManager cannot find rootElement '##{rootElement}'", @ unless @element

    for domevent, method of viewEventMap
      @element.on(domevent, null, { eventName: method }, @onApplicationEvent)

    events = (i for i, v of viewEventMap).join(' ')

    @element.on(events, '[view]', @onViewEvent)
    @element.on(events, '[data-mozart-action]', @onControlEvent)

    @openElements = {}

  # Find a view or a control with the specified element id
  # @param id [string] the DOM element id of the view or control
  # @return [Mozart.View] The view or control 
  #
  # Find is intended to assist debug from the browser console.
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

  # For a given event, iterate interested views in all layouts and call
  # clickInside on those views
  # @param [DOMEvent] event The DOM event to process
  checkClickInside: (event) =>
    return unless (event.type == 'click') 

    for layout in @layouts
      for id, view of layout.hasClickInside
        if $(event.target).parents('#'+id).length > 0
          Util.log('events','clickInside on', view,'(',event,')')
          view.clickInside()        

  # For a given event, iterate interested views in all layouts and call
  # clickOutside on those views
  # @param [DOMEvent] event The DOM event to process
  checkClickOutside: (event) =>
    return unless (event.type == 'click') 

    for layout in @layouts
      for id, view of layout.hasClickOutside
        if $(event.target).parents('#'+id).length == 0
          Util.log('events','clickOutside on', view,'(',event,')')
          view.clickOutside()

  # Release the DOMManager, unbinding from all DOM events on the rootElement
  release: =>
    for domevent, method of viewEventMap
      @element.off(domevent, null, @_checkRootEvent)

    events = (i for i, v of viewEventMap).join(' ')

    @element.off(events, '[view]', @onViewEvent)
    @element.off(events, '[data-mozart-action]', @onControlEvent)
    super

  # Publish an application level event on this DOMManager
  # @param [DOMEvent] event The DOM event to process
  onApplicationEvent: (event) =>
    @publish event.data.eventName, event

  # Process a DOMEvent by routing it to the containing view and
  # calling the appropriate hander on that view if defined
  # @param [DOMEvent] event The DOM event to process
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

  # Process a DOMEvent by routing it to the control and
  # calling the appropriate action hander on the containing view
  # onControlEvent will warn if the action handler does not exist.
  # @param [DOMEvent] event The DOM event to process
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
  # @param view [Mozart.View] The View which is the context for the '*Lookup' resolution
  # @param options [object] The map of attributes and paths which are copied or resolved.
  # @return [object] The resolved set of options, with Lookup values processed. 
  getControlOptionsValues: (view, options) =>
    out = {}
    for k,v of options
      if Util.stringEndsWith(k,'Lookup')
        k2 = Util.sliceStringBefore(k,'Lookup')
        out[k2] = Util._getPath(view, v)
      else
        out[k]=v
    out

exports.DOMManager = DOMManager