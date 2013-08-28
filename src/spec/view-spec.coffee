SpecTest = {} 

describe 'Mozart.View', ->

  beforeEach ->
    Mozart.root = @
    @SpecTest = {}

    @ele = $('<div>').appendTo($('body'))
    
    @tom = Mozart.MztObject.create({ name: 'tom', nationality: 'irish'})
    @john = Mozart.MztObject.create({ name: 'john', nationality: 'australian'})

    SpecTest.simpleViewFunction = Handlebars.compile('<p>{{customer.name}}</p>')

   afterEach ->
    @ele.remove()
    @SpecTest = {}

  it "should error when templateName doesn't exist in HandlebarsTemplates", ->
    class SpecTest.BadTemplateNameView extends Mozart.View
      templateName: "somevalueThatDoesntExist"

    createBadTemplateNameView = ->
      SpecTest.BadTemplateNameView.create()

    expect(createBadTemplateNameView).toThrow()

  it "should be able to render a simple view to DOM", ->
    class SpecTest.PersonView extends Mozart.View
      customer: null
      templateFunction: SpecTest.simpleViewFunction 

    @view = SpecTest.PersonView.create()
    @view.set('customer',@tom)
    @view.el = @ele[0]
    @view.prepareElement()
    @view.replaceElement()
    expect(@view.element.html()).toContain('tom')

  it "creates a local property using declared binding with bound value", ->
    @SpecTest.customerController = Mozart.MztObject.create()
    @SpecTest.customerController.set('customerValue', @john)
    
    class SpecTest.PersonView extends Mozart.View
      customerBinding: 'SpecTest.customerController.customerValue'
      templateFunction: SpecTest.simpleViewFunction 

    @view = SpecTest.PersonView.create()

    expect(@view.customer).toBeDefined()
    expect(@view.customer).toEqual(@john)

  it "creates a local property using declared binding with null value", ->
    @SpecTest.customerController = Mozart.MztObject.create()
    @SpecTest.customerController.set('customerValue', null)
    
    class SpecTest.PersonView extends Mozart.View
      customerBinding: 'SpecTest.customerController.customerValue'
      templateFunction: SpecTest.simpleViewFunction 

    @view = SpecTest.PersonView.create()

    expect(@view.customer).toBeDefined()
    expect(@view.customer).toEqual(null)

  it "should be able to render with declared syncWith binding", ->
    @SpecTest.customerController = Mozart.MztObject.create()
    
    class SpecTest.PersonView extends Mozart.View
      customerBinding: 'SpecTest.customerController.customer'
      templateFunction: SpecTest.simpleViewFunction 

    @view = SpecTest.PersonView.create()
    @view.el = @ele[0]

    @SpecTest.customerController.set('customer',@john)
    @view.prepareElement()
    @view.replaceElement()
    expect(@view.element.html()).toContain('john')

    @SpecTest.customerController.set('customer',@tom)
    @view.prepareElement()
    @view.replaceElement()
    expect(@view.element.html()).toContain('tom')


  it "should be able to render view with a bind helper", ->
    @SpecTest.customerController = Mozart.MztObject.create()
    @SpecTest.customerController.set('customer', @john)
    
    class SpecTest.PersonView extends Mozart.View
      customerBinding: 'SpecTest.customerController.customer'
      templateFunction: Handlebars.compile('<p>{{bind "customer.name"}}</p>', {data:true})

    @view = SpecTest.PersonView.create()
    @view.el = @ele[0]

    @view.prepareElement()
    @view.replaceElement()
    @view.postRender()

    expect(@view.get('customer')).toEqual(@john)
    expect(@view.element.text()).toContain('john')

    @john.set('name', 'dave')
    expect(@view.element.text()).toContain('dave')

  it "should be able to render view with two bind helpers", ->
    @SpecTest.customerController = Mozart.MztObject.create()
    @SpecTest.customerController.set('customer', @john)
    
    class SpecTest.PersonView extends Mozart.View
      customerBinding: 'SpecTest.customerController.customer'
      templateFunction: Handlebars.compile('<p>{{bind "customer.name"}} - XX{{bind "customer.name"}}XX</p>', {data:true})

    @view = SpecTest.PersonView.create()
    @view.el = @ele[0]

    @view.prepareElement()
    @view.replaceElement()
    @view.postRender()

    expect(@view.get('customer')).toEqual(@john)
    expect(@view.element.text()).toContain('john')
    expect(@view.element.text()).toContain('XXjohnXX')

    @john.set('name', 'dave')
    expect(@view.element.text()).toContain('dave')
    expect(@view.element.text()).toContain('XXdaveXX')

  it "should be able to bind onto a property from a parent view", ->
    class SpecTest.ParentView extends Mozart.View
      templateFunction: (context, data) -> ""
    @parentView = SpecTest.ParentView.create(customer: @john)

    class SpecTest.ChildView extends Mozart.View
      candidateBinding: 'parent.customer'
      templateFunction: (context, data) -> ""
    @childView = SpecTest.ChildView.create
      parent: @parentView 

    expect(@childView.get('candidate')).toEqual(@john)

  it "should be able to render with declared observe binding", ->
    @SpecTest.customerController = Mozart.MztObject.create()
    
    class SpecTest.PersonView extends Mozart.View
      customerObserveBinding: 'SpecTest.customerController.customer'
      templateFunction: SpecTest.simpleViewFunction 

    @view = SpecTest.PersonView.create()

    @SpecTest.customerController.set('customer',@john)
    expect(@view.get('customer')).toEqual(@john)

    @view.set('customer',@tom)
    expect(@SpecTest.customerController.get('customer')).toEqual(@john)

  it "should be able to render with declared notify binding", ->
    @SpecTest.customerController = Mozart.MztObject.create()
    
    class SpecTest.PersonView extends Mozart.View
      customerNotifyBinding: 'SpecTest.customerController.customer'
      templateFunction: SpecTest.simpleViewFunction 

    @view = SpecTest.PersonView.create()

    @view.set('customer',@tom)
    expect(@SpecTest.customerController.get('customer')).toEqual(@tom)

    @SpecTest.customerController.set('customer',@john)
    expect(@view.get('customer')).toEqual(@tom)

  it "should be able to render an Html property to an attribute", ->
    class SpecTest.PersonView extends Mozart.View
      customer: null
      templateFunction: SpecTest.simpleViewFunction
      oneHtml: 'tom'

    @view = SpecTest.PersonView.create()
    @view.el = @ele[0]
    @view.prepareElement()
    @view.replaceElement()
    expect(@view.element.attr('one')).toBe('tom')

  it "should be able to render an Html property to an attribute with bindings", ->
    @SpecTest.mainController = Mozart.MztObject.create()
    
    class SpecTest.PersonView extends Mozart.View
      templateFunction: SpecTest.simpleViewFunction
      oneHtmlObserveBinding: 'SpecTest.mainController.oneattr'

    @SpecTest.mainController.set 'oneattr', 'john'

    @view = SpecTest.PersonView.create()
    @view.el = @ele[0]
    @view.prepareElement()
    @view.replaceElement()
    expect(@view.element.attr('one')).toBe('john')

    @SpecTest.mainController.set 'oneattr', 'james'

    expect(@view.element.attr('one')).toBe('james')

  describe 'Auto Actions', ->
    it "should define and call an auto action targeting a controller", ->

      @SpecTest.testController = Mozart.MztObject.create
        testMethod: (view, d) =>
          expect(view).toEqual(@view)
          expect(d).toEqual({one:1})

      tm = spyOn(@SpecTest.testController,'testMethod').andCallThrough()

      class SpecTest.TestView extends Mozart.View
        templateFunction: SpecTest.simpleViewFunction

      @view = SpecTest.TestView.create
        testEventAction: 'SpecTest.testController.testMethod'
      
      @view.publish('testEvent', {one:1})

      expect(tm).toHaveBeenCalledWith(@view, {one:1}, 'testEvent')

    it "should define and call an auto action targeting the parent view", ->

      class SpecTest.ParentTestView extends Mozart.View
        templateFunction: SpecTest.simpleViewFunction

        testMethod: (view, d) =>
          expect(view).toEqual(@expectedView)
          expect(d).toEqual({one:1})

      class SpecTest.TestView extends Mozart.View
        templateFunction: SpecTest.simpleViewFunction

      @parentView = SpecTest.ParentTestView.create()

      tm = spyOn(@parentView,'testMethod').andCallThrough()

      @view = SpecTest.TestView.create
        parent: @parentView
        testEventAction: 'testMethod'
      
      @parentView.expectedView = @view
      
      @view.publish('testEvent', {one:1})

      expect(tm).toHaveBeenCalledWith(@view, {one:1}, 'testEvent')

    it "should define and call an auto action on two views", ->

      @SpecTest.testController = Mozart.MztObject.create
        testMethod: (view, d) =>
          expect(view).toEqual(@SpecTest.testController.expectedView)

      tm = spyOn(@SpecTest.testController,'testMethod').andCallThrough()

      class SpecTest.TestView extends Mozart.View
        templateFunction: SpecTest.simpleViewFunction

      @view = SpecTest.TestView.create
        testEventAction: 'SpecTest.testController.testMethod'

      @view2 = SpecTest.TestView.create
        testEventAction: 'SpecTest.testController.testMethod'
      
      @SpecTest.testController.expectedView = @view
      @view.publish('testEvent')
      expect(tm).toHaveBeenCalledWith(@view,undefined,'testEvent')

      @SpecTest.testController.expectedView = @view2
      @view2.publish('testEvent')
      expect(tm).toHaveBeenCalledWith(@view,undefined,'testEvent')

    it "should not call an auto action when disabled", ->

      @SpecTest.testController = Mozart.MztObject.create
        testMethod: (view, d) =>

      tm = spyOn(@SpecTest.testController,'testMethod').andCallThrough()

      class SpecTest.TestView extends Mozart.View
        templateFunction: SpecTest.simpleViewFunction
        disableAutoActions: true

      @view = SpecTest.TestView.create
        testEventAction: 'SpecTest.testController.testMethod'
      
      @view.publish('testEvent', {one:1})

      expect(tm).not.toHaveBeenCalled()
