Test = {}
Test.LocalStorage = {}
Test.LocalStorage.getId = ->
  Math.round(Math.random()*9999999)

localStorage.clear()

describe 'Mozart.LocalStorage', ->
  beforeEach ->
   
    Test.LocalStorage.Customer = Mozart.Model.create { modelName: 'Customer' }
    Test.LocalStorage.Customer.attributes { 'name': 'string' }
    Test.LocalStorage.Customer.localStorage()

    Test.LocalStorage.Store = Mozart.Model.create { modelName: 'Store' }
    Test.LocalStorage.Store.attributes { 'name': 'string' }
    Test.LocalStorage.Store.localStorage()

    Test.LocalStorage.Product = Mozart.Model.create { modelName: 'Product' }
    Test.LocalStorage.Product.attributes { 'name': 'string' }
    Test.LocalStorage.Product.localStorage()

    Test.LocalStorage.Order = Mozart.Model.create { modelName: 'Order' }
    Test.LocalStorage.Order.localStorage({prefix:"TestLSPrefix"})
    
    Test.LocalStorage.Store.hasMany Test.LocalStorage.Product, 'products'
    Test.LocalStorage.Product.belongsTo Test.LocalStorage.Store, 'store'

    Test.LocalStorage.Order.belongsToPoly [Test.LocalStorage.Store, Test.LocalStorage.Customer], 'from', 'from_id', 'from_type'

  afterEach ->
    Test.LocalStorage.Customer.destroyAllLocalStorage()
    Test.LocalStorage.Store.destroyAllLocalStorage()
    Test.LocalStorage.Product.destroyAllLocalStorage()
    Test.LocalStorage.Order.destroyAllLocalStorage()

  describe 'core', ->
    it 'should provide the localStorage model extension method', ->
      expect(Test.LocalStorage.Customer.localStorageOptions).toBeDefined()
      expect(Test.LocalStorage.Customer.localStorageOptions.prefix).toEqual('MozartLS')

    it 'should allow a different prefix', ->
      expect(Test.LocalStorage.Order.localStorageOptions.prefix).toEqual('TestLSPrefix')

    it 'shoudl provide the getLocalStoragePrefix method', ->
      expect(Test.LocalStorage.Customer.getLocalStoragePrefix()).toEqual("MozartLS-Customer")
      expect(Test.LocalStorage.Order.getLocalStoragePrefix()).toEqual("TestLSPrefix-Order")

  describe 'localStorage id mapping methods', ->
    beforeEach ->
      Test.LocalStorage.tom = Test.LocalStorage.Customer.createFromValues({name: 'Tom'})
      Test.LocalStorage.Customer.registerLocalStorageId(Test.LocalStorage.tom.id, '1236')

      Test.LocalStorage.bigcom = Test.LocalStorage.Store.createFromValues({name: 'Bigcom'})
      Test.LocalStorage.Store.registerLocalStorageId(Test.LocalStorage.bigcom.id, '2348')

    it 'should provide the registerLocalStorageId method on model', ->
      expect(Test.LocalStorage.Customer.getLocalStorageClientId('1236')).toEqual(Test.LocalStorage.tom.id)

    it 'should provide the unRegisterLocalStorageId method on model', ->
      Test.LocalStorage.Customer.unRegisterLocalStorageId(Test.LocalStorage.tom.id, '1236')
      expect(Test.LocalStorage.Customer.getLocalStorageClientId('1236')).toEqual(undefined)

    it 'should provide the getLocalStorageId method on model', ->
      expect(Test.LocalStorage.Customer.getLocalStorageId(Test.LocalStorage.tom.id)).toEqual('1236')

    it 'should provide the getLocalStorageId method on instance', ->
      expect(Test.LocalStorage.tom.getLocalStorageId()).toEqual('1236')

    it 'should provide the getLocalStorageClientId method', ->
      expect(Test.LocalStorage.Customer.getLocalStorageClientId('1236')).toEqual(Test.LocalStorage.tom.id)

    it 'should not pollute other models when registering localStorage ids', ->
      expect(Test.LocalStorage.Customer.getLocalStorageClientId('2348')).toEqual(undefined)
      expect(Test.LocalStorage.Customer.getLocalStorageId(Test.LocalStorage.bigcom.id)).toEqual(undefined)
      
      expect(Test.LocalStorage.Store.getLocalStorageClientId('1236')).toEqual(undefined)
      expect(Test.LocalStorage.Store.getLocalStorageId(Test.LocalStorage.tom.id)).toEqual(undefined)

  describe 'localStorage integration', ->
    beforeEach ->
      # Setup LocalStorage Records

      localStorage['MozartLS-Customer-index'] = "[2346,456345,345346,234235,876976,786788,123884,7732]"
      localStorage['MozartLS-Customer-2346'] = '{"name":"Tom Cully"}'
      localStorage['MozartLS-Customer-456345'] = '{"name":"Jason O\'Conal"}'
      localStorage['MozartLS-Customer-345346'] = '{"name":"Scott Christopher"}'
      localStorage['MozartLS-Customer-234235'] = '{"name":"Drew Karrasch"}'
      localStorage['MozartLS-Customer-876976'] = '{"name":"Luke Eller"}'
      localStorage['MozartLS-Customer-786788'] = '{"name":"Chris Roper"}'
      localStorage['MozartLS-Customer-123884'] = '{"name":"Pascal Zajac"}'
      localStorage['MozartLS-Customer-7732'] = '{"name":"Tim Massey"}'

      # Setup JSSide records
      Test.LocalStorage.tom = Test.LocalStorage.Customer.createFromValues({name: 'Tom'})
      Test.LocalStorage.jason = Test.LocalStorage.Customer.initInstance({name: 'Jason'})
      Test.LocalStorage.tomId = Test.LocalStorage.Customer.registerLocalStorageId(Test.LocalStorage.tom.id, Test.LocalStorage.getId())
      Test.LocalStorage.subcaller = 
        onLoad: ->
        onLoadAll: ->
        onCreate: ->
        onUpdate: ->
        onDestroy: ->
        onChange: ->

    it 'should load all from localStorage on model loadAllLocalStorage', ->
      spyOn(Test.LocalStorage.subcaller,'onChange')
      Test.LocalStorage.Customer.subscribeOnce('change', Test.LocalStorage.subcaller.onChange)
      Test.LocalStorage.Customer.loadAllLocalStorage()

      expect(Test.LocalStorage.subcaller.onChange).toHaveBeenCalled()
      jason = Test.LocalStorage.Customer.findByAttribute("name","Jason O'Conal")[0]
      expect(jason).toBeDefined()
      expect(jason.getLocalStorageId()).toEqual(456345)
      expect(Test.LocalStorage.Customer.findByAttribute("name","Jason O'Conal")).toBeDefined()
      expect(Test.LocalStorage.Customer.findByAttribute("name","Scott Christopher")).toBeDefined()
      expect(Test.LocalStorage.Customer.findByAttribute("name","Drew Karrasch")).toBeDefined()
      expect(Test.LocalStorage.Customer.findByAttribute("name","Luke Eller")).toBeDefined()
      expect(Test.LocalStorage.Customer.findByAttribute("name","Chris Roper")).toBeDefined()
      expect(Test.LocalStorage.Customer.findByAttribute("name","Pascal Zajac")).toBeDefined()

    it 'should load data from localStorage on loadLocalStorageId', ->
      spyOn(Test.LocalStorage.subcaller,'onLoad')
      spyOn(Test.LocalStorage.subcaller,'onChange')
      Test.LocalStorage.Customer.subscribeOnce('loadLocalStorageComplete', Test.LocalStorage.subcaller.onLoad)
      Test.LocalStorage.Customer.subscribeOnce('change', Test.LocalStorage.subcaller.onChange)

      Test.LocalStorage.Customer.loadLocalStorageId(7732)

      expect(Test.LocalStorage.subcaller.onLoad).toHaveBeenCalled()
      expect(Test.LocalStorage.subcaller.onChange).toHaveBeenCalled()
      instid = Test.LocalStorage.Customer.getLocalStorageClientId(7732)
      expect(instid).not.toBeNull()
      instance = Test.LocalStorage.Customer.findById(instid)
      expect(instance.name).toEqual('Tim Massey')

    it 'should load data from localStorage on instance loadLocalStorage', ->
      Test.LocalStorage.Customer.registerLocalStorageId(Test.LocalStorage.tom.id, 2346)
      spyOn(Test.LocalStorage.subcaller,'onLoad')
      spyOn(Test.LocalStorage.subcaller,'onChange')
      Test.LocalStorage.Customer.subscribeOnce('loadLocalStorageComplete', Test.LocalStorage.subcaller.onLoad)
      Test.LocalStorage.tom.subscribeOnce('change', Test.LocalStorage.subcaller.onChange)
      Test.LocalStorage.tom.loadLocalStorage()

      expect(Test.LocalStorage.subcaller.onLoad).toHaveBeenCalled()
      expect(Test.LocalStorage.subcaller.onChange).toHaveBeenCalled()
      expect(Test.LocalStorage.tom.name).toEqual("Tom Cully")
      expect(Test.LocalStorage.tom.getLocalStorageId()).toEqual(2346)

    it 'should post data to localStorage on save when instance isn\'t registered', ->
      spyOn(Test.LocalStorage.subcaller,'onCreate')
      spyOn(Test.LocalStorage.subcaller,'onChange')
      Test.LocalStorage.Customer.subscribeOnce('createLocalStorageComplete', Test.LocalStorage.subcaller.onCreate)
      Test.LocalStorage.Customer.subscribeOnce('change', Test.LocalStorage.subcaller.onChange)
      Test.LocalStorage.jason.save()

      expect(Test.LocalStorage.subcaller.onCreate).toHaveBeenCalled()
      expect(Test.LocalStorage.subcaller.onChange).toHaveBeenCalled()
      localStorageId = Test.LocalStorage.Customer.getLocalStorageId(Test.LocalStorage.jason.id)
      expect(parseInt(localStorageId)).toBeGreaterThan(0)

    it 'should put data to localStorage on save', ->
      spyOn(Test.LocalStorage.subcaller,'onUpdate')
      spyOn(Test.LocalStorage.subcaller,'onChange')
      Test.LocalStorage.Customer.subscribeOnce('updateLocalStorageComplete', Test.LocalStorage.subcaller.onUpdate)
      Test.LocalStorage.tom.set('name','Thomas Hugh Cully')
      Test.LocalStorage.tom.save()
      Test.LocalStorage.Customer.subscribeOnce('change', Test.LocalStorage.subcaller.onChange)

      expect(Test.LocalStorage.subcaller.onUpdate).toHaveBeenCalledWith(Test.LocalStorage.tom, undefined)
      expect(Test.LocalStorage.subcaller.onChange).not.toHaveBeenCalled()

    it 'should destroy on localStorage and unregister on destroy', ->
      spyOn(Test.LocalStorage.subcaller,'onDestroy')
      spyOn(Test.LocalStorage.subcaller,'onChange')
      Test.LocalStorage.Customer.subscribeOnce('destroyLocalStorageComplete', Test.LocalStorage.subcaller.onDestroy)
      Test.LocalStorage.tom.destroy()
      Test.LocalStorage.Customer.subscribeOnce('change', Test.LocalStorage.subcaller.onChange)

      expect(Test.LocalStorage.subcaller.onDestroy).toHaveBeenCalledWith(Test.LocalStorage.tomId, undefined)
      expect(Test.LocalStorage.Customer.getLocalStorageClientId(Test.LocalStorage.tomId)).not.toBeDefined()
      expect(Test.LocalStorage.subcaller.onChange).not.toHaveBeenCalled()

  describe 'model client -> localStorage object mapping', ->
    beforeEach ->
      Test.LocalStorage.tom = Test.LocalStorage.Customer.createFromValues({name: 'Tom'})
      Test.LocalStorage.tomId = Test.LocalStorage.Customer.registerLocalStorageId(Test.LocalStorage.tom.id,Test.LocalStorage.getId())

    describe 'for simple objects', ->
    
      it 'should provide the toLocalStorageObject method', ->
        object = Test.LocalStorage.Customer.toLocalStorageObject(Test.LocalStorage.tom)

        expect(object).not.toBe(Test.LocalStorage.tom)
        expect(object.name).toEqual(Test.LocalStorage.tom.name)
        expect(object.id).not.toEqual(Test.LocalStorage.tom.id)
        expect(object.id).toEqual(Test.LocalStorage.tomId)

      it 'should provide the toLocalStorageClientObject method, when the clientside instance does not exist', ->
        Test.LocalStorage.chrisID = Test.LocalStorage.getId()
        object = {
          id: Test.LocalStorage.chrisID
          name: 'Chris'
        }

        clientObject = Test.LocalStorage.Customer.toLocalStorageClientObject(object)
        expect(clientObject.id).toEqual(undefined)
        expect(Test.LocalStorage.Customer.records[clientObject.id]).toEqual(undefined)
        expect(clientObject.name).toEqual('Chris')
        expect(clientObject.id).not.toEqual(Test.LocalStorage.chrisID)

      it 'should provide the toLocalStorageClientObject method, when the clientside instance does exist', ->
        object = {
          id: Test.LocalStorage.tomId
          name: 'Tony'
        }

        clientObject = Test.LocalStorage.Customer.toLocalStorageClientObject(object)
        expect(Test.LocalStorage.Customer.records[clientObject.id]).toBe(Test.LocalStorage.tom)
        expect(clientObject.name).toEqual('Tony')
        expect(clientObject.id).not.toEqual(Test.LocalStorage.tomId)

    describe 'for objects with foreign keys', ->
      beforeEach ->
        Test.LocalStorage.bcId = Test.LocalStorage.getId()
        Test.LocalStorage.bc = Test.LocalStorage.Store.createFromValues({name: 'BigCom'})
        Test.LocalStorage.Store.registerLocalStorageId(Test.LocalStorage.bc.id, Test.LocalStorage.bcId)

        Test.LocalStorage.shoeId = Test.LocalStorage.getId()
        Test.LocalStorage.shoe = Test.LocalStorage.Product.createFromValues { name: 'Red Shoe' }
        Test.LocalStorage.Product.registerLocalStorageId(Test.LocalStorage.shoe.id, Test.LocalStorage.shoeId)

        Test.LocalStorage.hatId = Test.LocalStorage.getId()
        Test.LocalStorage.hat = Test.LocalStorage.Product.createFromValues { name: 'Blue Hat' }
        Test.LocalStorage.Product.registerLocalStorageId(Test.LocalStorage.hat.id, Test.LocalStorage.hatId)

        Test.LocalStorage.scarf = Test.LocalStorage.Product.createFromValues { name: 'Green Scarf' }
        # No Scarf LocalStorageId = unsaved to localStorage.

        Test.LocalStorage.tomId = Test.LocalStorage.getId()
        Test.LocalStorage.tom = Test.LocalStorage.Customer.createFromValues { name: 'Tom' }
        Test.LocalStorage.Customer.registerLocalStorageId(Test.LocalStorage.tom.id, Test.LocalStorage.tomId)

        Test.LocalStorage.shoeOrderId = Test.LocalStorage.getId() 
        Test.LocalStorage.shoeOrder = Test.LocalStorage.Order.createFromValues( { name: 'Customer Shoe Order' })
        Test.LocalStorage.Order.registerLocalStorageId(Test.LocalStorage.shoeOrder.id, Test.LocalStorage.shoeOrderId)

        Test.LocalStorage.shoeSupplyOrderId = Test.LocalStorage.getId()
        Test.LocalStorage.shoeSupplyOrder = Test.LocalStorage.Order.createFromValues( { name: 'Store Shoe Order'})
        Test.LocalStorage.Order.registerLocalStorageId(Test.LocalStorage.shoeSupplyOrder.id, Test.LocalStorage.shoeSupplyOrderId)

        Test.LocalStorage.bc.products().add(Test.LocalStorage.shoe)
        Test.LocalStorage.bc.products().add(Test.LocalStorage.hat)
        Test.LocalStorage.bc.products().add(Test.LocalStorage.scarf)

        Test.LocalStorage.shoeOrder.from(Test.LocalStorage.tom)
        #Test.LocalStorage.shoeSupplyOrder.from(Test.LocalStorage.bc)

      it 'should translate non-poly fks properly in toLocalStorageObject method', ->
        object = {
          id: Test.LocalStorage.shoeId
          name: 'Old Shoe'
          store_id: Test.LocalStorage.bcId 
        }

        clientObject = Test.LocalStorage.Product.toLocalStorageClientObject(object)
        expect(Test.LocalStorage.Product.records[clientObject.id]).toBe(Test.LocalStorage.shoe)
        expect(Test.LocalStorage.Store.records[clientObject.store_id]).toBe(Test.LocalStorage.bc)

      it 'should translate non-poly fks in toLocalStorageObject when fk is null', ->
        object = {
          id: Test.LocalStorage.shoeId
          name: 'Old Shoe'
          store_id: null
        }

        clientObject = Test.LocalStorage.Product.toLocalStorageClientObject(object)
        expect(Test.LocalStorage.Product.records[clientObject.id]).toBe(Test.LocalStorage.shoe)
        expect(clientObject.store_id).toBeNull()

      it 'should translate poly fks properly in toLocalStorageObject method', ->
        object = {
          name: 'Old Shoe'
          from_id: Test.LocalStorage.tomId
          from_type: 'Customer'
        }

        clientObject = Test.LocalStorage.Order.toLocalStorageClientObject(object)
        expect(Test.LocalStorage.Customer.records[clientObject.from_id]).toBe(Test.LocalStorage.tom)

        object = {
          name: 'Old Shoe'
          from_id: Test.LocalStorage.bcId
          from_type: 'Store'
        }

        clientObject = Test.LocalStorage.Order.toLocalStorageClientObject(object)
        expect(Test.LocalStorage.Store.records[clientObject.from_id]).toBe(Test.LocalStorage.bc)

      it 'should translate non-poly fks in toLocalStorageObject when fk is null', ->
        object = {
          name: 'Old Shoe'
          from_id: null
          from_type: null
        }

        clientObject = Test.LocalStorage.Order.toLocalStorageClientObject(object)
        expect(clientObject.from_id).toBeNull()




