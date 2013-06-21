Test = {}

describe 'Mozart.Core', ->

  beforeEach ->
    Mozart.root = @

    @test = { one: 1, two: null, four: { subten: 10 }, five: {subeight: { subthree: 3}} }

    @Mozartfour = Mozart.MztObject.create
      subten: 10

    @Mozart = Mozart.MztObject.create
      one: 1
      two: null
      four: @Mozartfour
      five:
        subeight:
          subthree: 3

  describe "Path parsing", ->

    it 'should parse a path', ->
      [path, attr] = Mozart.parsePath("one.two")
      expect(path).toEqual("one")
      expect(attr).toEqual("two")

    it 'should parse an extended path', ->
      [path, attr] = Mozart.parsePath("one.two.three")
      expect(path).toEqual("one.two")
      expect(attr).toEqual("three")

    it 'should return the path as attribute if not path', ->
      [path, attr] = Mozart.parsePath("one")
      expect(path).toEqual(null)
      expect(attr).toEqual("one")

  describe 'Object path mapping', ->

    describe 'for js objects', ->
      it 'should find the value of a property on an object', ->
        x = Mozart._getPath(@test,'one')
        expect(x).toEqual(1)

      it 'should find value of property on an object when the value is null', ->
        x = Mozart._getPath(@test,'two')
        expect(x).toEqual(null)

      it 'should throw when property on an object not found and no properties exist', ->
        x = -> Mozart.getPath(@test,'three')
        expect(x).toThrow()

      it 'should throw when property on an object not found and other properties exist', ->
        x = -> Mozart.getPath(@test,'four.subeight')
        expect(x).toThrow()

      it 'should return undefined when traversing a null value in a part of path', ->
        x = Mozart._getPath(@Mozart,'two.anything')
        expect(x).toEqual(undefined)

      it 'should find the value of a property by following the path on an object', ->
        expect(Mozart.getPath(@test,'four.subten')).toEqual(10)
        expect(Mozart.getPath(@test,'five.subeight.subthree')).toEqual(3)

      it 'should find a global reference with a no context', ->
        @Mozart = Mozart
        x = Mozart.getPath('Mozart.MztObject')
        expect(x).toEqual(Mozart.MztObject)

      it 'should find a global reference to the spec', ->
        @GlobalThing = Mozart.MztObject.create({personName: "tom"})
        x = Mozart.getPath('GlobalThing.personName')
        expect(x).toEqual("tom")

      it 'should find a global reference with a null context', ->
        @Mozart = Mozart
        x = Mozart.getPath(null, 'Mozart.MztObject')
        expect(x).toEqual(Mozart.MztObject)

      it 'should find a global reference with a non-null context', ->
        @Mozart = Mozart
        x = Mozart.getPath(@test,'Mozart.MztObject')
        expect(x).toEqual(Mozart.MztObject)

      it 'should find this as context', ->
        x = Mozart.getPath(@test,'this')
        expect(x).toBe(@test)

      it 'should find this as part of a path', ->
        x = Mozart.getPath(@test,'this.one')
        expect(x).toEqual(@test.one)

    describe 'for Mozart.MztObjects', ->
      it 'should find the value of a property on an object', ->
        get = spyOn(@Mozart,'get').andCallThrough()
        expect(Mozart.getPath(@Mozart,'one')).toEqual(1)
        expect(get).toHaveBeenCalled()

      it 'should find the value of a Mozart.MztObject property on an object', ->
        get = spyOn(@Mozart,'get').andCallThrough()
        gettwo = spyOn(@Mozartfour,'get').andCallThrough()
        expect(Mozart.getPath(@Mozart,'four.subten')).toEqual(10)
        expect(get).toHaveBeenCalled()
        expect(gettwo).toHaveBeenCalled()

      it 'should find the value of a property on an object when the value is null', ->
        expect(Mozart._getPath(@Mozart,'two')).toEqual(null)

      it 'should return undefined when traversing a null value in a part of path', ->
        expect(Mozart._getPath(@Mozart,'two.anything')).toEqual(undefined)

      it 'should throw when cannot find a property on an object', ->
        x = -> Mozart.getPath(@Mozart,'three')
        expect(x).toThrow()

      it 'should throw when cannot find a property on an object', ->
        x = -> Mozart.getPath(@Mozart,'four.subeight')
        expect(x).toThrow()

      it 'should find a sub-object by following the path on a object', ->
        expect(Mozart.getPath(@Mozart,'four.subten')).toEqual(10)
        expect(Mozart.getPath(@Mozart,'five.subeight.subthree')).toEqual(3)


      
