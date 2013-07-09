# Mozart.Handlebars spec

describe 'Mozart-handlebars', ->

  describe 'helper: action', ->

    beforeEach ->

      Mozart.root = @
      @Test = {}

      @Test.testController = Mozart.MztObject.create
        method3: ->
        toast:
          methodX: ->

      @mockLayout = Mozart.MztObject.create
        addControl: (action, options) ->

      @mockParentView = Mozart.MztObject.create
        method1: ->

      @mockView = Mozart.MztObject.create
        layout: @mockLayout
        parent: @mockParentView
        method2: ->

    it 'should correctly parse a non-path action with no target to current view', ->
      x = spyOn(@mockLayout, 'addControl')
      
      ret = Handlebars.helpers.action('method2', { data: @mockView, hash: {} } )
      expect(Mozart.stringStartsWith(ret.toString(),'data-mozart-action=')).toBeTruthy()

      actionId = parseInt(ret.toString().match(/[0-9]+/)[0])

      expect(x).toHaveBeenCalledWith(actionId, {
        action: 'method2'
        view: @mockView
        options: {}
        events: ["click"]
        allowDefault: false
      })

    it 'should correctly parse a path action with no target relative to current view', ->
      x = spyOn(@mockLayout, 'addControl')
      
      ret = Handlebars.helpers.action('parent.method1', { data: @mockView, hash: {} } )
      expect(Mozart.stringStartsWith(ret.toString(),'data-mozart-action=')).toBeTruthy()

      actionId = parseInt(ret.toString().match(/[0-9]+/)[0])
      
      expect(x).toHaveBeenCalledWith(actionId, {
        action: 'method1'
        view: @mockParentView
        options: {}
        events: ["click"]
        allowDefault: false
      })


    it 'should correctly parse an absolute path action with no target to a global', ->
      x = spyOn(@mockLayout, 'addControl')
      
      ret = Handlebars.helpers.action('Test.testController.method3', { data: @mockView, hash: {} } )
      expect(Mozart.stringStartsWith(ret.toString(),'data-mozart-action=')).toBeTruthy()

      actionId = parseInt(ret.toString().match(/[0-9]+/)[0])
      
      expect(x).toHaveBeenCalledWith(actionId, {
        action: 'method3'
        view: @Test.testController,
        options: {}
        events: ["click"]
        allowDefault: false
      })

    it 'should correctly parse a non-path action with a target to that target', ->
      x = spyOn(@mockLayout, 'addControl')
      
      ret = Handlebars.helpers.action('method1', { data: @mockView, hash: { target: 'parent'} } )
      expect(Mozart.stringStartsWith(ret.toString(),'data-mozart-action=')).toBeTruthy()

      actionId = parseInt(ret.toString().match(/[0-9]+/)[0])

      expect(x).toHaveBeenCalledWith(actionId, {
        action: 'method1'
        view: @mockParentView
        options: { target: 'parent' } 
        events: ["click"]
        allowDefault: false
      })

    it 'should correctly parse a path action with an absolute target to that target', ->
      x = spyOn(@mockLayout, 'addControl')
      
      ret = Handlebars.helpers.action('toast.methodX', { data: @mockView, hash: { target: 'Test.testController' } } )
      expect(Mozart.stringStartsWith(ret.toString(),'data-mozart-action=')).toBeTruthy()

      actionId = parseInt(ret.toString().match(/[0-9]+/)[0])

      expect(x).toHaveBeenCalledWith(actionId, {
        action: 'methodX'
        view: @Test.testController.toast
        options: { target: 'Test.testController' } 
        events: ["click"]
        allowDefault: false
      })
