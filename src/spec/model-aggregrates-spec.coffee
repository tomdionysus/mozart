Test = {}

describe 'Mozart.Model Aggregrates', ->

  beforeEach ->

    Test.Tag = Mozart.Model.create({ modelName: 'Tag' })
    Test.Tag.attributes
      name: 'string'

    Test.Transaction = Mozart.Model.create({ modelName: 'Transaction' })
    Test.Transaction.attributes
      description: 'string'
      amount: 'float'

    Test.TransactionTag = Mozart.Model.create()

    @north = Test.Tag.initInstance
      name: 'North Income'

    @south = Test.Tag.initInstance
      name: 'South Income'

    @wellington = Test.Transaction.initInstance
      description: 'Rent From Wellington'
      amount: 900.00

    @christchurch = Test.Transaction.initInstance
      description: 'Rent From Christchurch'
      amount: 100.00

    @magdala = Test.Transaction.initInstance
      description: 'Rent From Magdala'
      amount: 300.00

    @eastbourne = Test.Transaction.initInstance
      description: 'Rent From Eastbourne'
      amount: 550.00

    Test.Tag.hasManyThrough Test.Transaction, 'transactions', Test.TransactionTag
    Test.Transaction.hasManyThrough Test.Tag, 'tags', Test.TransactionTag

  describe "Aggregrate Functions on Model", ->
    describe 'sum', ->
      it 'should sum a float field properly', ->
        @magdala.save()
        @eastbourne.save()

        expect(Test.Transaction.sum('amount')).toEqual(850);

    describe 'average', ->
      it 'should average a float field properly', ->
        @magdala.save()
        @eastbourne.save()

        expect(Test.Transaction.average('amount')).toEqual(425);

  describe "Aggregrate Functions on InstanceCollection", ->
    beforeEach ->
      @magdala.save()
      @eastbourne.save()
      @christchurch.save()
      @wellington.save()

      @north.save();
      @south.save();

      @north.transactions().add(@eastbourne)
      @north.transactions().add(@wellington)
      @south.transactions().add(@christchurch)
      @south.transactions().add(@magdala)

    describe 'sum', ->
      it 'should sum only instances in the collection', ->
        expect(@north.transactions().sum('amount')).toEqual(1450)
        expect(@south.transactions().sum('amount')).toEqual(400)

    describe 'average', ->
      it 'should average only instances in the collection', ->
        expect(@north.transactions().average('amount')).toEqual(725)
        expect(@south.transactions().average('amount')).toEqual(200)


      