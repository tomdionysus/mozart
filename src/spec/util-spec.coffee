describe 'Util', ->

  describe 'helper methods', ->

    it 'should execute addBindingsParent correctly', ->

      f = ->
        return 1

      t = {
        one: 1
        two: 2
        threeBinding: 'test.one'
        fourObserveBinding: 'test.two'
        fiveNotifyBinding: 'test.three'
        sixBinding: 'Test.four'
        sevenObserveBinding: 'Test.five'
        eightNotifyBinding: 'Test.six'
        nineBinding: 'one'
        tenBinding: 'One'
        elevenBinding: f
        twelveBinding: 1
      }

      Mozart.addBindingsParent(t)

      expect(_.keys(t).length).toEqual(12)
      expect(t.one).toEqual(1)
      expect(t.two).toEqual(2)
      expect(t.threeBinding).toEqual('parent.test.one')
      expect(t.fourObserveBinding).toEqual('parent.test.two')
      expect(t.fiveNotifyBinding).toEqual('parent.test.three')
      expect(t.sixBinding).toEqual('Test.four')
      expect(t.sevenObserveBinding).toEqual('Test.five')
      expect(t.eightNotifyBinding).toEqual('Test.six')
      expect(t.nineBinding).toEqual('parent.one')
      expect(t.tenBinding).toEqual('One')
      expect(t.elevenBinding).toEqual(f)
      expect(t.twelveBinding).toEqual(1)
