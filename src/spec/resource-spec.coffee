Test = {}

describe 'Mozart.Resource', ->

  beforeEach ->
    Test.server = sinon.fakeServer.create()

  afterEach ->
    Test.server.restore()

  describe "instantiation", ->

    it "should error if no url is supplied", ->
      fn = -> Mozart.Resource.create({url: null})
      expect(fn).toThrow('Resource: Resource has no url')

    it "should error if no serverIdField is supplied", ->
      fn = -> Mozart.Resource.create({url:"1", serverIdField: null})
      expect(fn).toThrow('Resource: Resource has no serverIdField')

    it "should error if no clientApiField is supplied", ->
      fn = -> Mozart.Resource.create({url:"1",serverIdField:"1",clientApiField:null})
      expect(fn).toThrow('Resource: Resource has no clientApiField')

    it "should error if no model is supplied", ->
      fn = -> Mozart.Resource.create({url:"1",serverIdField:"1",clientApiField:"1",model: null})
      expect(fn).toThrow('Resource: Resource has no model')

    it "should error if no mapServerData is supplied", ->
      fn = -> 
        Mozart.Resource.create
          url:"1"
          serverIdField:"1"
          clientApiField:"1"
          model: "1"
          mapServerData: null
      expect(fn).toThrow('Resource: Resource must define mapServerData method')

    it "should error if mapServerData is not a function", ->
      fn = -> 
        Mozart.Resource.create
          url:"1"
          serverIdField:"1"
          clientApiField:"1"
          model: "1"
          mapServerData: 1
      expect(fn).toThrow('Resource: Resource must define mapServerData method')
    
    it "should error if no mapClientData is supplied", ->
      fn = -> 
        Mozart.Resource.create
          url:"1"
          serverIdField:"1"
          clientApiField:"1"
          model: "1"
          mapServerData: -> "ok"
          mapClientData: null
      expect(fn).toThrow('Resource: Resource must define mapClientData method')

    it "should error if mapClientData is not a function", ->
      fn = -> 
        Mozart.Resource.create
          url:"1"
          serverIdField:"1"
          clientApiField:"1"
          model: "1"
          mapServerData: -> "ok"
          mapClientData: 1
      expect(fn).toThrow('Resource: Resource must define mapClientData method')

    it "should instantiate correctly with all parameters supplied", ->

      model = Mozart.MztObject.create()
      spyOn(model,'subscribe')

      fn = -> 
        Mozart.Resource.create
          url:"1"
          serverIdField:"1"
          clientApiField:"1"
          model: model
          mapServerData: -> "ok"
          mapClientData: -> "ok"
      expect(fn).not.toThrow()

    it "should set up http and subscribe to events on model", ->

      model = Mozart.MztObject.create()
      spyOn(model,'subscribe')

      inst = Mozart.Resource.create
          url:"1"
          serverIdField:"1"
          clientApiField:"1"
          model: model
          mapServerData: -> "ok"
          mapClientData: -> "ok"

      expect(model.subscribe).toHaveBeenCalled()
      expect(inst.http instanceof Mozart.HTTP).toBeTruthy()

  describe "HTTP calls", ->

    beforeEach ->
      @inst = Mozart.Resource.create
        url:"1"
        serverIdField:"1"
        clientApiField:"1"
        model: 
          subscribe: -> 0
          findByAttribute: -> []
        mapServerData: -> "ok"
        mapClientData: -> "ok"

    it 'should call HTTP get on loadAll', ->
      spyOn(@inst.http,'get')

      @inst.loadAll(1,2)
      expect(@inst.http.get).toHaveBeenCalled()

    it 'should call HTTP get on load', ->
      spyOn(@inst.http,'get')

      @inst.load(1,2,3)
      expect(@inst.http.get).toHaveBeenCalled()

    it 'should not call HTTP post on create if server id exists', ->
      spyOn(@inst.http,'post')

      @inst.create({"1":"OK"},2)
      expect(@inst.http.post).not.toHaveBeenCalled()

    it 'should call HTTP post on create', ->
      spyOn(@inst.http,'post')

      @inst.create({},2)
      expect(@inst.http.post).toHaveBeenCalled()

    it 'should not call HTTP put on update if no server id field in instance', ->
      spyOn(@inst.http,'put')

      @inst.update({},2)
      expect(@inst.http.put).not.toHaveBeenCalled()

    it 'should call HTTP put on update', ->
      spyOn(@inst.http,'put')

      @inst.update({"1":"OK"},2)
      expect(@inst.http.put).toHaveBeenCalled()

    it 'should not call HTTP delete on destroy if no server id field in instance', ->
      spyOn(@inst.http,'delete')

      @inst.destroy({},2)
      expect(@inst.http.delete).not.toHaveBeenCalled()

    it 'should call HTTP delete on destroy', ->
      spyOn(@inst.http,'delete')

      @inst.destroy({"1":"OK"},2)
      expect(@inst.http.delete).toHaveBeenCalled()

  describe 'getForeignKey', ->

    beforeEach ->
      @inst = Mozart.Resource.create
        url:"1"
        serverIdField:"1"
        clientApiField:"1"
        model: 
          subscribe: -> 0
          findByAttribute: -> []
        mapServerData: -> "ok"
        mapClientData: -> "ok"

    it 'should call findByAttribute on model with the correct parameters', ->

      spyOn(@inst.model,'findByAttribute').andCallThrough()

      @inst.getForeignKey(@inst.model,2,3,4)
      expect(@inst.model.findByAttribute).toHaveBeenCalledWith(3,2)

    it 'should return null if nothing found', ->
      expect(@inst.getForeignKey(@inst.model,2,3,4)).toBeNull()

    it 'should return correct field value from returned array', ->
      @inst.model.findByAttribute = -> [{"id":"testServerId"}]
      expect(@inst.getForeignKey(@inst.model,2,3,"id")).toEqual("testServerId")





