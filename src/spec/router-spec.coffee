Test = {}

describe 'Mozart.Router', ->
  describe 'Browser History Mode', ->
    beforeEach ->
      Test.router = Mozart.Router.create()

      Test.testwrapper = 
        simpleroutecalled: ->

        complexroutecalled: ->

        unmatchedcalled: ->

        simpleroute: (data, params) =>
          Test.testwrapper.simpleroutecalled()
          expect(params.customer_id).toEqual('1237')
          
        complexroute: (data, params) =>
          Test.testwrapper.complexroutecalled()
          expect(params.customer_id).toEqual('5')
          expect(params.photo_id).toEqual('6')
          expect(data.extra).toEqual(1)
          
        unmatched: (data, params) =>
          Test.testwrapper.unmatchedcalled()

      Test.router.bind('noroute',-> Test.testwrapper.unmatched())
      Test.router.register('/customer/:customer_id', Test.testwrapper.simpleroute)
      Test.router.register('/customer/:customer_id/photos/:photo_id', Test.testwrapper.complexroute, { extra : 1 })
      
      spyOn(Test.testwrapper,'simpleroutecalled')
      spyOn(Test.testwrapper,'complexroutecalled')
      spyOn(Test.testwrapper,'unmatchedcalled')

      Test.router.start()

    afterEach ->
      Test.router.release()

    it 'instantiates correctly', ->
      expect(Test.router).toBeDefined()

    it 'registers and navigates routes to callbacks properly', ->
      runs -> Test.router.navigateRoute('/customer/1237')
      waitsFor((-> !Test.router.isNavigating), "Router never finished navigating", 1000)
      runs -> expect(Test.testwrapper.simpleroutecalled).toHaveBeenCalled()

      runs -> Test.router.navigateRoute('/customer/5/photos/6')
      waitsFor((-> !Test.router.isNavigating), "Router never finished navigating", 1000)
      runs -> expect(Test.testwrapper.complexroutecalled).toHaveBeenCalled()

      runs -> Test.router.navigateRoute('/pers')
      waitsFor((-> !Test.router.isNavigating), "Router never finished navigating", 1000)
      runs -> expect(Test.testwrapper.unmatchedcalled).toHaveBeenCalled()

      runs -> Test.router.navigateRoute('')
      waitsFor((-> !Test.router.isNavigating), "Router never finished navigating", 1000)
      runs -> expect(Test.testwrapper.unmatchedcalled).toHaveBeenCalled()

  describe 'Hash Routing Mode', ->
    beforeEach ->
      Test.router = Mozart.Router.create
        useHashRouting: true

      Test.testwrapper = 
        simpleroutecalled: ->

        complexroutecalled: ->

        unmatchedcalled: ->

        simpleroute: (data, params) =>
          Test.testwrapper.simpleroutecalled()
          expect(params.customer_id).toEqual('1237')
          
        complexroute: (data, params) =>
          Test.testwrapper.complexroutecalled()
          expect(params.customer_id).toEqual('5')
          expect(params.photo_id).toEqual('6')
          expect(data.extra).toEqual(1)
          
        unmatched: (data, params) =>
          Test.testwrapper.unmatchedcalled()

      Test.router.bind('noroute',-> Test.testwrapper.unmatched())
      Test.router.register('/customer/:customer_id', Test.testwrapper.simpleroute)
      Test.router.register('/customer/:customer_id/photos/:photo_id', Test.testwrapper.complexroute, { extra : 1 })
      
      spyOn(Test.testwrapper,'simpleroutecalled')
      spyOn(Test.testwrapper,'complexroutecalled')
      spyOn(Test.testwrapper,'unmatchedcalled')

      Test.router.start()

    afterEach ->
      Test.router.release()

    it 'instantiates correctly', ->
      expect(Test.router).toBeDefined()

    it 'registers and navigates routes to callbacks properly', ->
      runs -> Test.router.navigateRoute('/customer/1237')
      runs -> expect(Test.testwrapper.simpleroutecalled).toHaveBeenCalled()

      runs -> Test.router.navigateRoute('/customer/5/photos/6')
      runs -> expect(Test.testwrapper.complexroutecalled).toHaveBeenCalled()

      runs -> Test.router.navigateRoute('/pers')
      runs -> expect(Test.testwrapper.unmatchedcalled).toHaveBeenCalled()

      runs -> Test.router.navigateRoute('/')
      runs -> expect(Test.testwrapper.unmatchedcalled).toHaveBeenCalled()

      runs -> Test.router.navigateRoute('#/customer/1237')
      runs -> expect(Test.testwrapper.unmatchedcalled).toHaveBeenCalled()

    it 'registers and navigates routes to callbacks properly on hashChange', ->
      runs -> 
        window.location.hash = '#/customer/1237'
        Test.router.onHashChange()
      runs -> expect(Test.testwrapper.simpleroutecalled).toHaveBeenCalled()

      runs -> 
        window.location.hash = '#/customer/5/photos/6'
        Test.router.onHashChange()
      runs -> expect(Test.testwrapper.complexroutecalled).toHaveBeenCalled()

      runs -> 
        window.location.hash = '#/pers'
        Test.router.onHashChange()
      runs -> expect(Test.testwrapper.unmatchedcalled).toHaveBeenCalled()
