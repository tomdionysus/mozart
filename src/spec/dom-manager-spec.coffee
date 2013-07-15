Test = {}

Test.doEvent = (target, eventName, extra) ->
  evt = jQuery.Event(eventName)
  evt[k] = v for k, v of extra if extra?
  target.trigger(evt)

Test.doKeyEvent = (target, eventName, key) ->
  Test.doEvent(target, eventName, {
    ctrlKey: false
    which: key
  })

describe "Mozart.DOMManager", ->

  beforeEach ->
    Test.dommgr = Mozart.DOMManager.create
      rootElement: 'body'

  afterEach ->
    Test.dommgr.release()
    delete Test['dommgr']

  describe "Root Element Key Events", ->

    beforeEach ->
      Test.callSpy =
        keyUpCalled: ->
        keyDownCalled: ->
        keyPressCalled: ->

    it "should allow binds to keyUp event", ->
      Test.dommgr.subscribe('keyUp', -> Test.callSpy.keyUpCalled())

      spyOn Test.callSpy, "keyUpCalled"

      Test.doKeyEvent($('body'),'keyup',27)

      expect(Test.callSpy.keyUpCalled).toHaveBeenCalled()
      Test.dommgr.release()

    it "should allow binds to keyDown event", ->
      Test.dommgr.subscribe('keyDown', -> Test.callSpy.keyDownCalled())

      spyOn Test.callSpy, "keyDownCalled"

      Test.doKeyEvent($('body'),'keydown',27)

      expect(Test.callSpy.keyDownCalled).toHaveBeenCalled()
      Test.dommgr.release()

    it "should allow binds to keyPressCalled event", ->
      Test.dommgr.subscribe('keyPress', -> Test.callSpy.keyPressCalled())

      spyOn Test.callSpy, "keyPressCalled"

      Test.doKeyEvent($('body'),'keypress',27)

      expect(Test.callSpy.keyPressCalled).toHaveBeenCalled()
      Test.dommgr.release()

    it "should unsubscribe events on release", ->
      Test.dommgr.subscribe('keyUp', -> Test.callSpy.keyUpCalled())

      spyOn Test.callSpy, "keyUpCalled"

      Test.dommgr.release()

      Test.doKeyEvent($('body'),'keyup',27)

      expect(Test.callSpy.keyUpCalled).not.toHaveBeenCalled()

  class Test.EventTestView extends Mozart.View
    templateFunction: -> ""

    init: ->
      super

    bindEvent: ->
      # This is necessary to do spy properly.
      @subscribe('click', @doElementClick)

    click: (evt, view) ->
    doElementClick: (evt, data, pubdata) ->

  describe "View Element Events", ->

    beforeEach ->
      @layoutRoot = $('<div>').attr('id',"dom-manager-test-main")
      $('body').append(@layoutRoot)

      Test.layout = Mozart.Layout.create
        rootElement: '#dom-manager-test-main'
        states: [
          Mozart.Route.create
            viewClass: Test.EventTestView
            path: "/"
        ]

      Test.dommgr.layouts = [
        Test.layout
      ]

      Test.layout.bindRoot()

    afterEach ->
      @layoutRoot.remove()
      Test.layout.release()
      delete Test['layout']

    it 'should publish a click event on a view when its element is clicked', ->

      runs -> 
        Test.layout.navigateRoute('/')
      waits 20
      runs ->
        x = sinon.spy(Test.layout.currentView,'click')
        y = sinon.spy(Test.layout.currentView,'doElementClick')
        
        Test.layout.currentView.bindEvent()
        evt = Test.doEvent(Test.layout.currentView.element, 'click')

        expect(x.calledOnce).toBeTruthy()
        expect(y.calledOnce).toBeTruthy()


