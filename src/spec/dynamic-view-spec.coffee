SpecTest = {} 

describe 'Mozart.DynamicView', ->

  beforeEach ->
    Mozart.root = window
    @SpecTest = {}

    @ele = $('<div>')
    $('body').append(@ele)
    
    @layout = Mozart.Layout.create(
      rootElement: @ele
      states: []
    )

    @layout.start()

  afterEach ->
    @ele.remove()
    @SpecTest = {}

  it "should render a set of views", ->
    tfn = ->
      'Test!'

    tfn2 = ->
      'Test2!'

    @view = @layout.createView(Mozart.DynamicView,
      schema: [
        { viewClass: "Mozart.View", templateFunction: tfn, name: "testNamedView", paramOne: "paramOneValue" },
        "Test 2"
        { viewClass: "Mozart.View", templateFunction: tfn2, name: "testNamedView2", paramOne: "paramOneValue" },
      ]
    )

    @view.element = @ele
    @layout.queueRenderView(@view)
    @layout.processRenderQueue()

    expect(_.keys(@view.childViews).length).toEqual(2)
    expect(@view.element.html()).toContain('Test 2')


