Test = window.Test = @Test = {}
Spec = window.Spec = @Spec = {}

describe 'Mozart.MztObject', ->

  describe 'Mixins', ->
    Mozart.TestMixin = 
      test: -> 'Mozart.TestMixin.text'

    class TestModule1 extends Mozart.MztObject
      @extend Mozart.TestMixin

    class TestModule2 extends Mozart.MztObject
      @include Mozart.TestMixin

    it 'should allow call on mixin on instance when extended', ->
      t = TestModule1.create()
      expect(t.test()).toEqual('Mozart.TestMixin.text')
      expect(TestModule1.test).not.toBeDefined()

    it 'should allow call on mixin on instance when included', ->
      t = TestModule2.create()
      expect(t.test).not.toBeDefined()
      expect(TestModule2.test()).toEqual('Mozart.TestMixin.text')

  describe 'Events', ->
    beforeEach ->
      class Test.EventTestClass extends Mozart.MztObject
      @t = Test.EventTestClass.create()

      @testproc = 
        testcallback1: (data) ->
          expect(data.prop1).toEqual('propone')

        testcallback2: (data) ->
          expect(data.prop2).toEqual('proptwo')

        testcallback1_1: (data) ->
          expect(data.prop2).toEqual('proptwo')

      spyOn(@testproc,'testcallback1')
      spyOn(@testproc,'testcallback2')
      spyOn(@testproc,'testcallback1_1')

    it 'should bind and trigger an event', ->
      @t.bind 'testeventone' , @testproc.testcallback1
      @t.trigger 'testeventone', { prop1: 'propone' }

      expect(@testproc.testcallback1).toHaveBeenCalled()
      expect(@testproc.testcallback2).not.toHaveBeenCalled()

    it 'should bind and trigger multiple events', ->
      @t.bind 'testeventone' , @testproc.testcallback1
      @t.bind 'testeventtwo' , @testproc.testcallback2
      
      @t.trigger 'testeventone', { prop1: 'propone' }
      expect(@testproc.testcallback1).toHaveBeenCalled()
      @t.trigger 'testeventtwo', { prop2: 'proptwo' }
      expect(@testproc.testcallback2).toHaveBeenCalled()

    it 'should bind and trigger multiple callbacks on one event', ->
      @t.bind 'testeventone' , @testproc.testcallback1
      @t.bind 'testeventone' , @testproc.testcallback1_1
      
      @t.trigger 'testeventone', { prop1: 'propone' }
      expect(@testproc.testcallback1).toHaveBeenCalled()
      expect(@testproc.testcallback1_1).toHaveBeenCalled()

    it 'should unbind from a single event and callback', ->
      @t.bind 'testeventone' , @testproc.testcallback1
      @t.bind 'testeventone' , @testproc.testcallback1_1

      @t.unbind 'testeventone', @testproc.testcallback1_1

      @t.trigger 'testeventone', { prop1: 'propone' }

      expect(@testproc.testcallback1).toHaveBeenCalled()
      expect(@testproc.testcallback1_1).not.toHaveBeenCalled()

    it 'should unbind all callbacks from a single event', ->
      @t.bind 'testeventone' , @testproc.testcallback1
      @t.bind 'testeventone' , @testproc.testcallback1_1
      @t.bind 'testeventtwo' , @testproc.testcallback2

      @t.unbind 'testeventone'

      @t.trigger 'testeventone', { prop1: 'propone' }
      @t.trigger 'testeventtwo', { prop2: 'proptwo' }

      expect(@testproc.testcallback1).not.toHaveBeenCalled()
      expect(@testproc.testcallback1_1).not.toHaveBeenCalled()
      expect(@testproc.testcallback2).toHaveBeenCalled()

    it 'should unbind all callbacks', ->
      @t.bind 'testeventone' , @testproc.testcallback1
      @t.bind 'testeventone' , @testproc.testcallback1_1
      @t.bind 'testeventtwo' , @testproc.testcallback2

      @t.unbind()

      @t.trigger 'testeventone', { prop1: 'propone' }
      @t.trigger 'testeventtwo', { prop2: 'proptwo' }

      expect(@testproc.testcallback1).not.toHaveBeenCalled()
      expect(@testproc.testcallback1_1).not.toHaveBeenCalled()
      expect(@testproc.testcallback2).not.toHaveBeenCalled()

    it 'should bind and trigger a one event, and not trigger it twice', ->
      @t.one 'testeventone' , @testproc.testcallback1
      @t.trigger 'testeventone', { prop1: 'propone' }

      expect(@testproc.testcallback1).toHaveBeenCalled()

      @testproc.testcallback1.reset()
      @t.trigger 'testeventone', { prop1: 'propone' }

      expect(@testproc.testcallback1).not.toHaveBeenCalled()
  
  describe "Getters and Setters", ->
    beforeEach ->
      @obj = Mozart.MztObject.create
        coffee: 'black'

        whiskey: null

        tea: -> 'english'

    it 'should be able to get an attribute', ->
      expect(@obj.get('coffee')).toEqual('black') 

    it 'should get undefined for a property that doesn\'t exist', ->
      expect(@obj.get('milo')).toEqual(undefined)

    it 'should get null for a property that exists with no value', ->
      expect(@obj.get('whiskey')).toEqual(null)  

    it 'should be able to get an function with a value', ->
      expect(@obj.get('tea')).toEqual('english')

    it 'should be able to set an attribute', ->
      @obj.set('coffee', 'flat-white')
      expect(@obj.coffee).toEqual('flat-white') 

    it 'should be error if attempting to set an function', ->
      test = -> @obj.set('coffee', 'flat-white')
      expect(test).toThrow()

  describe "Lookup Properties", ->
    beforeEach ->
      Mozart.root = @
      @Spec = {}

    it 'should correctly get lookup properties', ->
      @Spec.one = "one1"

      x = Mozart.MztObject.create
        valueLookup: 'Spec.one'

      expect(x.value).toEqual("one1")

    it 'should correctly get lookup properties with null values', ->
      @Spec.one = null

      x = Mozart.MztObject.create
        valueLookup: 'Spec.one'

      expect(x.value).toBeNull()

    it 'should set undefined on get lookup property with bad path', ->
      delete @Spec["one"]

      x = Mozart.MztObject.create
        valueLookup: 'Spec.one'

      expect(x.value).not.toBeDefined()

  describe "Bindings", ->
    
    beforeEach ->
      Mozart.root = window

      Spec.personController = Mozart.MztObject.create()
      @tom = Mozart.MztObject.create({name: 'tom'})
      @john = Mozart.MztObject.create({name: 'john'})

    it "should set up binding stuff", ->
      expect(@tom._bindings.notify).toBeDefined()
      expect(@tom._bindings.notify).toEqual({})
    
    describe "Notify Bindings", ->

      it "should add the binding to the internal map when transferable", ->
        @view = Mozart.MztObject.create
          personNotifyBinding: 'Spec.personController.subject'

        expect(_.keys(@view._bindings.notify).length).toEqual(1)
        expect(@view._bindings.notify.person).toBeDefined()
        expect(@view._bindings.notify.subject).toBeUndefined()
        expect(@view._bindings.notify.person.length).toEqual(1)
        expect(@view._bindings.notify.person[0]).toEqual({attr:'subject', target: Spec.personController, transferable: true})

        expect(_.keys(Spec.personController._bindings.observe).length).toEqual(1)
        expect(Spec.personController._bindings.observe.subject).toBeDefined()
        expect(Spec.personController._bindings.observe.person).toBeUndefined()
        expect(Spec.personController._bindings.observe.subject.length).toEqual(1)
        expect(Spec.personController._bindings.observe.subject[0]).toEqual({attr:'person', target: @view, transferable: true})

      it "should add the binding to the internal map when non-transferable", ->
        @cheston = Mozart.MztObject.create
          name: 'Cheston'

        @view = Mozart.MztObject.create
          subject: @cheston
          personNotifyBinding: 'subject.name'

        expect(_.keys(@view._bindings.notify).length).toEqual(1)
        expect(@view._bindings.notify.person).toBeDefined()
        expect(@view._bindings.notify.subject).toBeUndefined()
        expect(@view._bindings.notify.person.length).toEqual(1)
        expect(@view._bindings.notify.person[0]).toEqual({attr:'name', target: @cheston, transferable: false})

        expect(_.keys(@cheston._bindings.observe).length).toEqual(1)
        expect(@cheston._bindings.observe.name).toBeDefined()
        expect(@cheston._bindings.observe.person).toBeUndefined()
        expect(@cheston._bindings.observe.name.length).toEqual(1)
        expect(@cheston._bindings.observe.name[0]).toEqual({attr:'person', target: @view, transferable: false})

      it "should change target on set", ->
        @view = Mozart.MztObject.create
          personNotifyBinding: 'Spec.personController.subject'

        @view.set 'person', @tom
        expect(Spec.personController.subject).toEqual(@tom)

        @view.set 'person', @john
        expect(Spec.personController.subject).toEqual(@john)

        @view.set 'person', null
        expect(Spec.personController.subject).toBeNull()

      it "should set initial value", ->
        @view = Mozart.MztObject.create
          person: @tom
          personNotifyBinding: 'Spec.personController.subject'

        expect(Spec.personController.subject).toEqual(@tom)

      it 'should allow multiple objects to notify one object', ->
        @view1 = Mozart.MztObject.create
          personNotifyBinding: 'Spec.personController.subject'

        @view2 = Mozart.MztObject.create
          personNotifyBinding: 'Spec.personController.subject'

        expect(Spec.personController.subject).toBeUndefined()
        @view1.set('person', @tom)
        expect(Spec.personController.subject).toEqual(@tom)
        @view2.set('person', @john)
        expect(Spec.personController.subject).toEqual(@john)

      it 'should allow bindings to be removed', ->
        @view = Mozart.MztObject.create
          personNotifyBinding: 'Spec.personController.subject'

        @view.set 'person', @tom
        expect(Spec.personController.subject).toEqual(@tom)

        @view._removeBinding('person', Spec.personController, 'subject', Mozart.MztObject.NOTIFY)
        
        @view.set 'person', @john
        expect(Spec.personController.subject).toEqual(@tom)

        @view.set 'person', null
        expect(Spec.personController.subject).toEqual(@tom)

    describe "Observe Bindings", ->

      it 'should add the binding to the internal map of the target when transferable', ->
        @view = Mozart.MztObject.create
          personObserveBinding: 'Spec.personController.subject'

        expect(_.keys(Spec.personController._bindings.notify).length).toEqual(1)
        expect(Spec.personController._bindings.notify.subject).toBeDefined()
        expect(Spec.personController._bindings.notify.person).toBeUndefined()
        expect(Spec.personController._bindings.notify.subject.length).toEqual(1)
        expect(Spec.personController._bindings.notify.subject[0]).toEqual({attr:'person', target: @view, transferable: true})

        expect(_.keys(@view._bindings.observe).length).toEqual(1)
        expect(@view._bindings.observe.person).toBeDefined()
        expect(@view._bindings.observe.subject).toBeUndefined()
        expect(@view._bindings.observe.person.length).toEqual(1)
        expect(@view._bindings.observe.person[0]).toEqual({attr:'subject', target: Spec.personController, transferable: true})

      it 'should add the binding to the internal map of the target when non-transferable', ->
        @john = Mozart.MztObject.create
          subject: "John"

        @view = Mozart.MztObject.create
          parent: @john
          personObserveBinding: 'parent.subject'

        expect(_.keys(@john._bindings.notify).length).toEqual(1)
        expect(@john._bindings.notify.subject).toBeDefined()
        expect(@john._bindings.notify.person).toBeUndefined()
        expect(@john._bindings.notify.subject.length).toEqual(1)
        expect(@john._bindings.notify.subject[0]).toEqual({attr:'person', target: @view, transferable: false})

        expect(_.keys(@view._bindings.observe).length).toEqual(1)
        expect(@view._bindings.observe.person).toBeDefined()
        expect(@view._bindings.observe.subject).toBeUndefined()
        expect(@view._bindings.observe.person.length).toEqual(1)
        expect(@view._bindings.observe.person[0]).toEqual({attr:'subject', target: @john, transferable: false})

      it "should change target on set", ->
        @view = Mozart.MztObject.create
          personObserveBinding: 'Spec.personController.subject'

        Spec.personController.set 'subject', @tom
        expect(@view.person).toEqual(@tom)

        Spec.personController.set 'subject', @john
        expect(@view.person).toEqual(@john)

        Spec.personController.set 'subject', null
        expect(@view.person).toBeNull()

      it "should set initial value", ->
        Spec.personController.set 'subject', @tom

        @view = Mozart.MztObject.create
          personObserveBinding: 'Spec.personController.subject'

        expect(@view.person).toEqual(@tom)

      it "should allow multiple objects to observe one object", ->
        Spec.personController.set 'subject', @tom

        @view1 = Mozart.MztObject.create
          personObserveBinding: 'Spec.personController.subject'

        @view2 = Mozart.MztObject.create
          personObserveBinding: 'Spec.personController.subject'

        expect(@view1.person).toEqual(@tom)
        expect(@view2.person).toEqual(@tom)

        Spec.personController.set 'subject', @john

        expect(@view1.person).toEqual(@john)
        expect(@view2.person).toEqual(@john)

      it "should allow bindings to be removed", ->
        @view = Mozart.MztObject.create
          personObserveBinding: 'Spec.personController.subject'

        Spec.personController.set 'subject', @tom
        expect(@view.person).toEqual(@tom)

        @view._removeBinding('person', Spec.personController, 'subject', Mozart.MztObject.OBSERVE)

        Spec.personController.set 'subject', @john
        expect(@view.person).toEqual(@tom)

        Spec.personController.set 'subject', null
        expect(@view.person).toEqual(@tom)

    describe "Sync Bindings", ->

      it 'should add the binding to the internal map of both the target and the target', ->
        @view = Mozart.MztObject.create
          personBinding: 'Spec.personController.subject'

        expect(_.keys(@view._bindings.notify).length).toEqual(1)
        expect(@view._bindings.notify.person).toBeDefined()
        expect(@view._bindings.notify.subject).toBeUndefined()
        expect(@view._bindings.notify.person[0]).toEqual({attr:'subject', target: Spec.personController, transferable: true})

        expect(_.keys(Spec.personController._bindings.notify).length).toEqual(1)
        expect(Spec.personController._bindings.notify.subject).toBeDefined()
        expect(Spec.personController._bindings.notify.person).toBeUndefined()
        expect(Spec.personController._bindings.notify.subject[0]).toEqual({attr:'person', target: @view, transferable: true})

      it "should change target on set in both directions", ->
        @view = Mozart.MztObject.create
          personBinding: 'Spec.personController.subject'

        Spec.personController.set 'subject', @tom
        expect(@view.person).toEqual(@tom)

        Spec.personController.set 'subject', @john
        expect(@view.person).toEqual(@john)

        Spec.personController.set 'subject', null
        expect(@view.person).toBeNull()

        @view.set 'person', @tom
        expect(Spec.personController.subject).toEqual(@tom)

        @view.set 'person', @john
        expect(Spec.personController.subject).toEqual(@john)

        @view.set 'person', null
        expect(Spec.personController.subject).toBeNull()

      it "should allow a binding to be removed", ->
        @view = Mozart.MztObject.create
          personBinding: 'Spec.personController.subject'

        Spec.personController.set 'subject', @tom
        expect(@view.person).toEqual(@tom)

        @view.set 'person', @john
        expect(Spec.personController.subject).toEqual(@john)

        @view._removeBinding('person', Spec.personController, 'subject', Mozart.MztObject.SYNC)

        Spec.personController.set 'subject', @tom
        expect(@view.person).toEqual(@john)

        @view.set 'person', null
        expect(Spec.personController.subject).toEqual(@tom)

        Spec.personController.set 'subject', @tom
        expect(@view.person).toEqual(null)

        @view.set 'person', @john
        expect(Spec.personController.subject).toEqual(@tom)

    describe "Relative Bindings", ->

      it "should allow bindings on relative object paths", ->

        @view1 = Mozart.MztObject.create
          name: "TC"

        @view2 = Mozart.MztObject.create
          parent: @view1
          parentNameBinding: "parent.name"

        expect(@view2.parentName).toEqual("TC")

        @view1.set("name","DOC")
        expect(@view2.parentName).toEqual("DOC")

        @view2.set("parentName","PZ")
        expect(@view1.name).toEqual("PZ")

    describe "Bindings on targets that change", ->

      it 'should write to the correct object after a change', ->
        Spec.personController.set 'subject', Mozart.MztObject.create({name:'Test'})

        @view = Mozart.MztObject.create
          subjectNameObserveBinding: 'Spec.personController.subject.name'

        Spec.personController.set 'subject', @tom
        expect(@view.subjectName).toEqual(@tom.name)

        Spec.personController.set 'subject', @john
        expect(@view.subjectName).toEqual(@john.name)

      it 'should preserve bindings when a bound property is set to null then back', ->
        Spec.personController.set 'subject', Mozart.MztObject.create({name:'Test'})

        @view = Mozart.MztObject.create
          subjectNameObserveBinding: 'Spec.personController.subject.name'

        Spec.personController.set 'subject', @tom
        expect(@view.subjectName).toEqual(@tom.name)

        Spec.personController.set 'subject', null
        expect(@view.subjectName).toEqual(null)

        Spec.personController.set 'subject', @john
        expect(@view.subjectName).toEqual(@john.name)

    describe "Bindings and circular references", ->

      it 'should handle circular references without an infinite loop', ->

        a = Mozart.MztObject.create()
        b = Mozart.MztObject.create()
        c = Mozart.MztObject.create()

        a._createBinding('test', b, 'test', Mozart.MztObject.SYNC, false)
        b._createBinding('test', c, 'test', Mozart.MztObject.SYNC, false)
        c._createBinding('test', a, 'test', Mozart.MztObject.SYNC, false)

        a.set('test', 'one')
        expect(b.test).toEqual('one')
        expect(c.test).toEqual('one')

        b.set('test', 'two')
        expect(a.test).toEqual('two')
        expect(c.test).toEqual('two')

        c.set('test', 'three')
        expect(b.test).toEqual('three')
        expect(a.test).toEqual('three')

    describe "Binding chaining", ->

      it 'should not pollute objects when transfering bindings', ->

        a = Mozart.MztObject.create({id:1})
        b = Mozart.MztObject.create({id:2})
        c = Mozart.MztObject.create({id:3})

        Test.controller = Mozart.MztObject.create()

        Mozart.root = window

        e = Mozart.MztObject.create(
          activeObserveBinding: "Test.controller.content"
        )

        Test.controller.set('content',a)
        expect(Test.controller.content.id).toEqual(1)
        expect(e.active.id).toEqual(1)

        Test.controller.set('content',b)
        expect(Test.controller.content.id).toEqual(2)
        expect(e.active.id).toEqual(2)

        Test.controller.set('content',c)
        expect(Test.controller.content.id).toEqual(3)
        expect(e.active.id).toEqual(3)

      it "should not transfer non-transferable bindings", ->

        Mozart.root = window

        @objA = Mozart.MztObject.create
          name: 'Cheston'

        @objA2 = Mozart.MztObject.create
          parent:@objA
          parentNameObserveBinding: 'parent.name'

        @objB = Mozart.MztObject.create
          name: 'Ginger'

        @objB2 = Mozart.MztObject.create
          parent:@objB
          parentNameObserveBinding: 'parent.name'

        Test.controller = Mozart.MztObject.create
          subject: @objA
          
        @observer = Mozart.MztObject.create
          subjectNameObserveBinding: 'Test.controller.subject.name'

        expect(@observer.subjectName).toEqual('Cheston')

        expect(@objA2.parentName).toEqual('Cheston')
        expect(@objB2.parentName).toEqual('Ginger')

        Test.controller.set('subject', @objB)

        expect(@observer.subjectName).toEqual('Ginger')

        expect(@objA2.parentName).toEqual('Cheston')
        expect(@objB2.parentName).toEqual('Ginger')

    describe "Binding removal", ->
      it "should remove the correct binding when an object is released", ->

        Mozart.root = window

        window.trace = true

        Test.controller = Mozart.MztObject.create
          subject: 'one'

        y = Mozart.MztObject.create
          testObserveBinding: 'Test.controller.subject'

        z = Mozart.MztObject.create
          testObserveBinding: 'Test.controller.subject'

        Test.controller.set('subject', 'two')
        expect(y.test).toEqual('two')
        expect(z.test).toEqual('two')

        #y._removeBinding('subject', Test.controller, 'subject', Mozart.MztObject.OBSERVE)
        y.release()

        Test.controller.set('subject', 'three')

        expect(z.test).toEqual('three')

        window.trace = false
