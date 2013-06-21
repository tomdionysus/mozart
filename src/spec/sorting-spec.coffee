describe 'Mozart.parseSort', ->
  beforeEach ->

    @one = Mozart.MztObject.create({name:'one', value:"1"})
    @two = Mozart.MztObject.create({name:'two', value:"2"})
    @three = Mozart.MztObject.create({name:'three', value:"3"})
    @four = Mozart.MztObject.create({name:'four', value:"4"})
    @five = Mozart.MztObject.create({name:'five', value:"5"})

    @arr = [ @two, @four, @five, @one, @three ]

  it 'should sort by value', ->
    key = "name"
    arr = @arr.sort( (a,b) -> b[key] - a[key] )

    key = "name"
    arr2 = @arr.sort( (a,b) -> a[key] - b[key] )

  describe 'argument parsing', ->
    it 'should parse a single value', ->
      x = Mozart.parseSort('one')
      expect(x).toEqual(['one'])

    it 'should parse multiple values', ->
      x = Mozart.parseSort('one,two')
      expect(x).toEqual(['one','two'])

    it 'should parse nested values', ->
      x = Mozart.parseSort('one,two,[three,four]')
      expect(x).toEqual(['one','two',['three','four']])

    it 'should parse multiple nested values', ->
      x = Mozart.parseSort('one,two,[three,four],[five,six]')
      expect(x).toEqual(['one','two',['three','four'],['five','six']])

    it 'should throw on invalid input ', ->
      x = -> Mozart.parseSort('one,two[three,four]')
      expect(x).toThrow('parseSort: Unexpected Character [ at 8')

