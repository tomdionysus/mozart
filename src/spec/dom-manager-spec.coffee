Test = {}

Test.doKeyEvent = (target, eventName,key) ->
  press = jQuery.Event(eventName)
  press.ctrlKey = false
  press.which = key
  target.trigger(press)

describe "Mozart.DOMManager", ->

  describe "Root Element Key Events", ->

    beforeEach ->
      Test.callSpy =
        keyUpCalled: ->
        keyDownCalled: ->
        keyPressCalled: ->

      Test.layout = Mozart.DOMManager.create
        rootElement: $('body')

    xit "should allow binds to keyUp event", ->
      Test.layout.bind('keyUp', -> Test.callSpy.keyUpCalled())

      spyOn Test.callSpy, "keyUpCalled"

      Test.doKeyEvent($('body'),'keyup',27)

      expect(Test.callSpy.keyUpCalled).toHaveBeenCalled()
      Test.layout.release()

    it "should allow binds to keyDown event", ->
      Test.layout.bind('keyDown', -> Test.callSpy.keyDownCalled())

      spyOn Test.callSpy, "keyDownCalled"

      Test.doKeyEvent($('body'),'keydown',27)

      expect(Test.callSpy.keyDownCalled).toHaveBeenCalled()
      Test.layout.release()

    it "should allow binds to keyPressCalled event", ->
      Test.layout.bind('keyPress', -> Test.callSpy.keyPressCalled())

      spyOn Test.callSpy, "keyPressCalled"

      Test.doKeyEvent($('body'),'keypress',27)

      expect(Test.callSpy.keyPressCalled).toHaveBeenCalled()
      Test.layout.release()

    it "should unbind events on release", ->
      Test.layout.bind('keyUp', -> Test.callSpy.keyUpCalled())

      spyOn Test.callSpy, "keyUpCalled"

      Test.layout.release()

      Test.doKeyEvent($('body'),'keyup',27)

      expect(Test.callSpy.keyUpCalled).not.toHaveBeenCalled()

