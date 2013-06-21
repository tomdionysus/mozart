Test = {}

describe 'Mozart.Route', ->
  it 'should not throw when instatiated normally', ->
    expect( ->
      Mozart.Route.create
        path: "/"
        viewClass: {}
    ).not.toThrow()

describe 'Mozart.Layout', ->
  it 'should have the correct properties on init', ->
    inst = Mozart.Layout.create
      states: [
        Mozart.Route.create
          name: ''
          path: '/'
          viewClass: {}
      ]
    expect(inst.viewRenderQueue).toEqual([])
    expect(inst.views).toEqual({})

  it 'should take a rootElement if supplied on init', ->
    mockEle = $("<div>")
    inst = Mozart.Layout.create
      rootElement: mockEle
      states: [
        Mozart.Route.create
          path: '/'
          viewClass: {}
      ]
    expect(inst.rootElement).toBe(mockEle)

  describe 'View tests', ->
    beforeEach ->
      @mockEle = $("<div id='test-one'>")
      @mockEle.attr('style','display:none')
      $('body').append(@mockEle)

      @mock = 
        mockempty: (params) ->
          expect(params).toEqual({})

        mockone: (params) ->
          expect(params.id).toEqual('1')

        mocktwo: (params) ->
          expect(params.two).toEqual(2)

      @mockViewClassDefault = class DefaultView extends Mozart.View
        templateFunction: Handlebars.compile("<p>DefaultView</p>")

      @mockViewClassPeopleList = class ViewPeopleList extends Mozart.View
        templateFunction: Handlebars.compile("<p>ViewPeopleList</p>")

      @mockViewClassPeopleShow = class ViewPeopleShow extends Mozart.View
        templateFunction: Handlebars.compile("<p>ViewPeopleShow</p>")

      Xthis = @

      @inst = Mozart.Layout.create
        rootElement: @mockEle
        states: [
          Mozart.Route.create
            name: 'customersshow'
            path: '/customers/:id'
            viewClass: @mockViewClassPeopleShow
            enter: (params) ->
              Xthis.mock.mockone(params)
              true

          Mozart.Route.create
            name: 'customerslist'
            path: '/customers'
            viewClass: @mockViewClassPeopleList
            enter: (params) ->
              Xthis.mock.mockempty(params)
              true

          Mozart.Route.create
            name: 'default'
            path: '/'
            viewClass: @mockViewClassDefault
        ]

      @inst.start()

      spyOn(@mock,'mockempty')
      spyOn(@mock,'mockone')

    afterEach ->
      @inst.release()

    it 'should register the supplied views', ->
      routes = (i for i,v of @inst.routes)
      expect(routes).toContain('/customers/:id')
      expect(routes).toContain('/customers')

    it 'should render correct views', ->
      runs -> @inst.navigateRoute('/')
      waits 20
      runs -> @inst.navigateRoute('/customers/1')
      waits 20
      runs -> expect(@mock.mockone).toHaveBeenCalled()
