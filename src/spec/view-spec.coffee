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
      templateName: ''
    @parentView = SpecTest.ParentView.create(customer: @john)

    class SpecTest.ChildView extends Mozart.View
      candidateBinding: 'parent.customer'
      templateName: ''
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



