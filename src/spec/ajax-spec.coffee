Test = {}
Test.Ajax = {}
Test.Ajax.getId = ->
  Math.round(Math.random()*9999999)

describe 'Mozart.Ajax', ->

  beforeEach ->

    Test.server = sinon.fakeServer.create()

    Test.Ajax.Customer = Mozart.Model.create { modelName: 'Customer' }
    Test.Ajax.Customer.attributes { 'name': 'string' }
    Test.Ajax.Customer.ajax { url: '/test/customers', interface: 'rest' }

    Test.Ajax.Store = Mozart.Model.create { modelName: 'Store' }
    Test.Ajax.Store.attributes { 'name': 'string' }
    Test.Ajax.Store.ajax { url: '/test/stores', interface: 'rest' }

    Test.Ajax.Product = Mozart.Model.create { modelName: 'Product' }
    Test.Ajax.Product.attributes { 'name': 'string' }
    Test.Ajax.Product.ajax { url: '/test/products', interface: 'rest' }

    Test.Ajax.Order = Mozart.Model.create { modelName: 'Order' }
    Test.Ajax.Order.ajax { url: '/test/orders', interface: 'rest' }
    
    Test.Ajax.Store.hasMany Test.Ajax.Product, 'products'
    Test.Ajax.Product.belongsTo Test.Ajax.Store, 'store'

    Test.Ajax.Order.belongsToPoly [Test.Ajax.Store, Test.Ajax.Customer], 'from', 'from_id', 'from_type'

  afterEach ->
    Test.server.restore()

  describe 'ajax core', ->
    it 'should provide the ajax model extension method', ->
      expect(Test.Ajax.Customer.url).toEqual('/test/customers')
      expect(Test.Ajax.Customer.interface).toEqual('rest')

    describe 'server id mapping methods', ->
      beforeEach ->
        Test.Ajax.tom = Test.Ajax.Customer.createFromValues({name: 'Tom'})
        Test.Ajax.Customer.registerServerId(Test.Ajax.tom.id, '1236')

        Test.Ajax.bigcom = Test.Ajax.Store.createFromValues({name: 'Bigcom'})
        Test.Ajax.Store.registerServerId(Test.Ajax.bigcom.id, '2348')

      it 'should provide the registerServerId method on model', ->
        expect(Test.Ajax.Customer.getClientId('1236')).toEqual(Test.Ajax.tom.id)

      it 'should provide the unRegisterServerId method on model', ->
        Test.Ajax.Customer.unRegisterServerId(Test.Ajax.tom.id, '1236')
        expect(Test.Ajax.Customer.getClientId('1236')).toEqual(undefined)

      it 'should provide the getServerId method on model', ->
        expect(Test.Ajax.Customer.getServerId(Test.Ajax.tom.id)).toEqual('1236')

      it 'should provide the getServerId method on instance', ->
        expect(Test.Ajax.tom.getServerId()).toEqual('1236')

      it 'should provide the getClientId method', ->
        expect(Test.Ajax.Customer.getClientId('1236')).toEqual(Test.Ajax.tom.id)

      it 'should not pollute other models when registering server ids', ->
        expect(Test.Ajax.Customer.getClientId('2348')).toEqual(undefined)
        expect(Test.Ajax.Customer.getServerId(Test.Ajax.bigcom.id)).toEqual(undefined)
        
        expect(Test.Ajax.Store.getClientId('1236')).toEqual(undefined)
        expect(Test.Ajax.Store.getServerId(Test.Ajax.tom.id)).toEqual(undefined)

  describe 'server integration', ->
    beforeEach ->
      Test.Ajax.tom = Test.Ajax.Customer.createFromValues({name: 'Tom'})
      Test.Ajax.jason = Test.Ajax.Customer.initInstance({name: 'Jason'})
      Test.Ajax.tomId = Test.Ajax.Customer.registerServerId(Test.Ajax.tom.id, Test.Ajax.getId())
      Test.Ajax.subcaller = 
        onLoad: ->
        onLoadAll: ->
        onCreate: ->
        onUpdate: ->
        onDestroy: ->
        onChange: ->

    it 'should load all from server on model load', ->
      runs ->
        Test.server.respondWith("GET", "/test/customers",
          [
            200, { "Content-Type": "application/json" },
          '[ { "id": 456345, "name": "Jason O\'Conal" }, { "id": 345346, "name": "Scott Christopher" }, { "id": 234235, "name": "Drew Karrasch" }, { "id": 876976, "name": "Luke Eller" }, { "id": 786788, "name": "Chris Roper" }, { "id": 123884, "name": "Pascal Zajac" }]'
          ]
        )
        spyOn(Test.Ajax.subcaller,'onChange')
        Test.Ajax.Customer.one('change', Test.Ajax.subcaller.onChange)
        Test.Ajax.Customer.loadAll()
        Test.server.respond()
      waitsFor((-> Test.Ajax.subcaller.onChange.calls.length > 0), "onChange not fired", 1000)
      runs ->
        expect(Test.Ajax.subcaller.onChange).toHaveBeenCalled()
        jason = Test.Ajax.Customer.findByAttribute("name","Jason O'Conal")[0]
        expect(jason).not.toBeNull()
        expect(jason.getServerId()).toEqual(456345)
        expect(Test.Ajax.Customer.findByAttribute("name","Jason O'Conal")).not.toBeNull()
        expect(Test.Ajax.Customer.findByAttribute("name","Scott Christopher")).not.toBeNull()
        expect(Test.Ajax.Customer.findByAttribute("name","Drew Karrasch")).not.toBeNull()
        expect(Test.Ajax.Customer.findByAttribute("name","Luke Eller")).not.toBeNull()
        expect(Test.Ajax.Customer.findByAttribute("name","Chris Roper")).not.toBeNull()
        expect(Test.Ajax.Customer.findByAttribute("name","Pascal Zajac")).not.toBeNull()

    it 'should load data from server on load with id', ->
      runs ->
        Test.server.respondWith("GET", "/test/customers/7732",
          [ 200, { "Content-Type": "application/json" }, '{ "id": 7732, "name": "Tim Massey" }' ])

        spyOn(Test.Ajax.subcaller,'onLoad')
        spyOn(Test.Ajax.subcaller,'onChange')
        Test.Ajax.Customer.one('loadComplete', Test.Ajax.subcaller.onLoad)
        Test.Ajax.Customer.one('change', Test.Ajax.subcaller.onChange)
        Test.Ajax.Customer.load(7732)
        Test.server.respond()
      waitsFor((-> Test.Ajax.subcaller.onChange.calls.length > 0), "onChange not fired", 1000)
      runs ->
        expect(Test.Ajax.subcaller.onLoad).toHaveBeenCalled()
        expect(Test.Ajax.subcaller.onChange).toHaveBeenCalled()
        instid = Test.Ajax.Customer.getClientId(7732)
        expect(instid).not.toBeNull()
        instance = Test.Ajax.Customer.findById(instid)
        expect(instance.name).toEqual('Tim Massey')

    it 'should load data from server on instance load', ->
      runs ->
        Test.server.respondWith("GET", "/test/customers/2346",
          [ 200, { "Content-Type": "application/json" }, '{ "id": 2346, "name": "Tom Cully" }' ])
        Test.Ajax.Customer.registerServerId(Test.Ajax.tom.id,2346)
        spyOn(Test.Ajax.subcaller,'onLoad')
        spyOn(Test.Ajax.subcaller,'onChange')
        Test.Ajax.Customer.one('loadComplete', Test.Ajax.subcaller.onLoad)
        Test.Ajax.tom.one('change', Test.Ajax.subcaller.onChange)
        Test.Ajax.tom.load()
        Test.server.respond()
      waitsFor((-> Test.Ajax.subcaller.onChange.calls.length > 0), "onChange not fired", 1000)
      runs ->
        expect(Test.Ajax.subcaller.onLoad).toHaveBeenCalledWith(Test.Ajax.tom, undefined)
        expect(Test.Ajax.subcaller.onChange).toHaveBeenCalled()
        expect(Test.Ajax.tom.name).toEqual("Tom Cully")
        expect(Test.Ajax.tom.getServerId()).toEqual(2346)

    it 'should post data to server on save when instance isn\'t registered', ->
      runs ->
        Test.server.respondWith("POST", "/test/customers",
          [ 200, { "Content-Type": "application/json" }, '{ "id": 3012 }' ])
        spyOn(Test.Ajax.subcaller,'onCreate')
        spyOn(Test.Ajax.subcaller,'onChange')
        Test.Ajax.Customer.one('createComplete', Test.Ajax.subcaller.onCreate)
        Test.Ajax.jason.save()
        Test.Ajax.Customer.one('change', Test.Ajax.subcaller.onChange)
        Test.server.respond()
      waitsFor((-> Test.Ajax.subcaller.onCreate.calls.length > 0), "onCreate not fired", 1000)
      runs ->
        expect(Test.Ajax.subcaller.onCreate).toHaveBeenCalled()
        expect(Test.Ajax.subcaller.onChange).not.toHaveBeenCalled()
        serverId = Test.Ajax.Customer.getServerId(Test.Ajax.jason.id)
        expect(serverId).toEqual(3012)

    it 'should put data to server on save', ->
      runs ->
        Test.server.respondWith(/\/customers\/(\d+)/, (xhr, id) ->
          xhr.respond(200, { "Content-Type": "application/json" }, '[{ "id": ' + id + ' }]')
        )
        
        spyOn(Test.Ajax.subcaller,'onUpdate')
        spyOn(Test.Ajax.subcaller,'onChange')
        Test.Ajax.Customer.one('updateComplete', Test.Ajax.subcaller.onUpdate)
        Test.Ajax.tom.set('name','Thomas Hugh Cully')
        Test.Ajax.tom.save()
        Test.Ajax.Customer.one('change', Test.Ajax.subcaller.onChange)
        Test.server.respond()
      waitsFor((-> Test.Ajax.subcaller.onUpdate.calls.length > 0), "onUpdate not fired", 1000)
      runs ->
        expect(Test.Ajax.subcaller.onUpdate).toHaveBeenCalledWith(Test.Ajax.tom, undefined)
        expect(Test.Ajax.subcaller.onChange).not.toHaveBeenCalled()

    it 'should destroy on server and unregister on destroy', ->
      runs ->
        Test.server.respondWith(/\/customers\/(\d+)/, (xhr, id) ->
          xhr.respond(200, { "Content-Type": "application/json" }, '[{ "id": ' + id + ' }]')
        )
        spyOn(Test.Ajax.subcaller,'onDestroy')
        spyOn(Test.Ajax.subcaller,'onChange')
        Test.Ajax.Customer.one('destroyComplete', Test.Ajax.subcaller.onDestroy)
        Test.Ajax.tom.destroy()
        Test.Ajax.Customer.one('change', Test.Ajax.subcaller.onChange)
        Test.server.respond()
      waitsFor((-> Test.Ajax.subcaller.onDestroy.calls.length > 0), "onDestroy not fired", 1000)
      runs ->
        expect(Test.Ajax.subcaller.onDestroy).toHaveBeenCalledWith(Test.Ajax.tomId, undefined)
        expect(Test.Ajax.Customer.getClientId(Test.Ajax.tomId)).not.toBeDefined()
        expect(Test.Ajax.subcaller.onChange).not.toHaveBeenCalled()

  describe 'model client -> server object mapping', ->
    beforeEach ->
      Test.Ajax.tom = Test.Ajax.Customer.createFromValues({name: 'Tom'})
      Test.Ajax.tomId = Test.Ajax.Customer.registerServerId(Test.Ajax.tom.id,Test.Ajax.getId())

    describe 'for simple objects', ->
    
      it 'should provide the toServerObject method', ->
        object = Test.Ajax.Customer.toServerObject(Test.Ajax.tom)

        expect(object).not.toBe(Test.Ajax.tom)
        expect(object.name).toEqual(Test.Ajax.tom.name)
        expect(object.id).not.toEqual(Test.Ajax.tom.id)
        expect(object.id).toEqual(Test.Ajax.tomId)

      it 'should provide the toClientObject method, when the clientside instance does not exist', ->
        Test.Ajax.chrisID = Test.Ajax.getId()
        object = {
          id: Test.Ajax.chrisID
          name: 'Chris'
        }

        clientObject = Test.Ajax.Customer.toClientObject(object)
        expect(clientObject.id).toEqual(undefined)
        expect(Test.Ajax.Customer.records[clientObject.id]).toEqual(undefined)
        expect(clientObject.name).toEqual('Chris')
        expect(clientObject.id).not.toEqual(Test.Ajax.chrisID)

      it 'should provide the toClientObject method, when the clientside instance does exist', ->
        object = {
          id: Test.Ajax.tomId
          name: 'Tony'
        }

        clientObject = Test.Ajax.Customer.toClientObject(object)
        expect(Test.Ajax.Customer.records[clientObject.id]).toBe(Test.Ajax.tom)
        expect(clientObject.name).toEqual('Tony')
        expect(clientObject.id).not.toEqual(Test.Ajax.tomId)

    describe 'for objects with foreign keys', ->
      beforeEach ->
        Test.Ajax.bcId = Test.Ajax.getId()
        Test.Ajax.bc = Test.Ajax.Store.createFromValues({name: 'BigCom'})
        Test.Ajax.Store.registerServerId(Test.Ajax.bc.id, Test.Ajax.bcId)

        Test.Ajax.shoeId = Test.Ajax.getId()
        Test.Ajax.shoe = Test.Ajax.Product.createFromValues { name: 'Red Shoe' }
        Test.Ajax.Product.registerServerId(Test.Ajax.shoe.id, Test.Ajax.shoeId)

        Test.Ajax.hatId = Test.Ajax.getId()
        Test.Ajax.hat = Test.Ajax.Product.createFromValues { name: 'Blue Hat' }
        Test.Ajax.Product.registerServerId(Test.Ajax.hat.id, Test.Ajax.hatId)

        Test.Ajax.scarf = Test.Ajax.Product.createFromValues { name: 'Green Scarf' }
        # No Scarf ServerId = unsaved to server.

        Test.Ajax.tomId = Test.Ajax.getId()
        Test.Ajax.tom = Test.Ajax.Customer.createFromValues { name: 'Tom' }
        Test.Ajax.Customer.registerServerId(Test.Ajax.tom.id, Test.Ajax.tomId)

        Test.Ajax.shoeOrderId = Test.Ajax.getId() 
        Test.Ajax.shoeOrder = Test.Ajax.Order.createFromValues( { name: 'Customer Shoe Order' })
        Test.Ajax.Order.registerServerId(Test.Ajax.shoeOrder.id, Test.Ajax.shoeOrderId)

        Test.Ajax.shoeSupplyOrderId = Test.Ajax.getId()
        Test.Ajax.shoeSupplyOrder = Test.Ajax.Order.createFromValues( { name: 'Store Shoe Order'})
        Test.Ajax.Order.registerServerId(Test.Ajax.shoeSupplyOrder.id, Test.Ajax.shoeSupplyOrderId)

        Test.Ajax.bc.products().add(Test.Ajax.shoe)
        Test.Ajax.bc.products().add(Test.Ajax.hat)
        Test.Ajax.bc.products().add(Test.Ajax.scarf)

        Test.Ajax.shoeOrder.from(Test.Ajax.tom)
        #Test.Ajax.shoeSupplyOrder.from(Test.Ajax.bc)

      it 'should translate non-poly fks properly in toServerObject method', ->
        object = {
          id: Test.Ajax.shoeId
          name: 'Old Shoe'
          store_id: Test.Ajax.bcId 
        }

        clientObject = Test.Ajax.Product.toClientObject(object)
        expect(Test.Ajax.Product.records[clientObject.id]).toBe(Test.Ajax.shoe)
        expect(Test.Ajax.Store.records[clientObject.store_id]).toBe(Test.Ajax.bc)

      it 'should translate non-poly fks in toServerObject when fk is null', ->
        object = {
          id: Test.Ajax.shoeId
          name: 'Old Shoe'
          store_id: null
        }

        clientObject = Test.Ajax.Product.toClientObject(object)
        expect(Test.Ajax.Product.records[clientObject.id]).toBe(Test.Ajax.shoe)
        expect(clientObject.store_id).toBeNull()

      it 'should translate poly fks properly in toServerObject method', ->
        object = {
          name: 'Old Shoe'
          from_id: Test.Ajax.tomId
          from_type: 'Customer'
        }

        clientObject = Test.Ajax.Order.toClientObject(object)
        expect(Test.Ajax.Customer.records[clientObject.from_id]).toBe(Test.Ajax.tom)

        object = {
          name: 'Old Shoe'
          from_id: Test.Ajax.bcId
          from_type: 'Store'
        }

        clientObject = Test.Ajax.Order.toClientObject(object)
        expect(Test.Ajax.Store.records[clientObject.from_id]).toBe(Test.Ajax.bc)

      it 'should translate non-poly fks in toServerObject when fk is null', ->
        object = {
          name: 'Old Shoe'
          from_id: null
          from_type: null
        }

        clientObject = Test.Ajax.Order.toClientObject(object)
        expect(clientObject.from_id).toBeNull()

  describe 'Nested Objects', ->
    beforeEach ->
     
      Test.Ajax.Nested = Mozart.Model.create { modelName: 'Nested' }
      Test.Ajax.Nested.attributes { 'name': 'string', 'nested':'object' }
      Test.Ajax.Nested.ajax { url: '/test/nestedjson', interface: 'rest' }

    it 'should read a nested object', ->
      runs ->
        Test.server.respondWith(/\/test\/nestedjson\/(\d+)/, (xhr, id) ->
          xhr.respond(200, { "Content-Type": "application/json" }, JSON.stringify({ id: id, name: 'horse', nested: { test1:1, test2: 2, listof: [1,2,3] } }))
        )
        Test.Ajax.Nested.load(2)
        Test.server.respond()
      waits(200)
      runs ->
        x = Test.Ajax.Nested.all()[0]
        expect(x.name).toEqual('horse')
        expect(x.nested.test1).toEqual(1)
        expect(x.nested.test2).toEqual(2)
        expect(x.nested.listof.length).toEqual(3)


