Test = {}

describe 'Mozart.Model', ->
  beforeEach ->
    Test.Customer = Mozart.Model.create({ modelName: 'Customer' })
    Test.Customer.attributes
      name: 'string'
      age: 'integer'

  it 'configure: should have correct model with correct settings', ->
    expect(Test.Customer).toBeDefined()
    expect(Test.Customer.modelName).toEqual('Customer')

  it 'attributes: should have the correct attributes', ->
    attr = Test.Customer.attrs
    expect(attr.id).toBeDefined()
    expect(attr.id).toEqual('integer')
    expect(attr.name).toBeDefined()
    expect(attr.name).toEqual('string')
    expect(attr.age).toBeDefined()
    expect(attr.age).toEqual('integer')
    expect(_(attr).keys().length).toEqual(3)

  it 'initInstance: should return correct instanceClass', ->
    instClass = Test.Customer.initInstance()
    expect(instClass.modelClass).toEqual(Test.Customer)

  describe 'Mozart.Instance', ->
    it '_getInstance: should return new instances', ->
      i1 = Test.Customer._getInstance()
      i2 = Test.Customer._getInstance()
      i3 = Test.Customer._getInstance()

      expect(i1).not.toBe(i2)
      expect(i2).not.toBe(i3)
      expect(i3).not.toBe(i1)
      expect(i1).not.toBe(i3)

    it 'should allow save and then find an instance', ->
      instClass = Test.Customer.initInstance
        name: 'Tom Cully'
        age: 33
      id = instClass.id

      # Id should not exist first
      expect(Test.Customer.exists(id)).toBeFalsy()

      # Save the record
      instClass.save()

      # Id Should now exist
      expect(Test.Customer.exists(id)).toBeTruthy()

      instClass = Test.Customer.findById(id)
      expect(instClass).toBeDefined()

      expect(instClass.name).toEqual('Tom Cully')
      expect(instClass.age).toEqual(33)

    it 'should disallow creating an instance with an existing id', ->
      instClass = Test.Customer.initInstance
        name: 'Tom Cully'
        age: 33
      id = instClass.id

      instClass.save()

      instClass = Test.Customer.initInstance
        name : 'Paul O\'Grady'
        age : 54
      instClass.id = id

      expect(-> 
        Test.Customer.createInstance(instClass)
      ).toThrow()

      instClass = Test.Customer.findById(id)
      expect(instClass).toBeDefined()
      expect(instClass.name).toEqual('Tom Cully')
      expect(instClass.age).toEqual(33)

    it 'should update an instance', ->
      instClass = Test.Customer.initInstance
        name: 'Tom Cully'
        age: 33
      id = instClass.id
      instClass.save()

      instClass = Test.Customer.findById(id)
      instClass.set('name','john smith') 
      instClass.set('age', 29)
     
      instClass = Test.Customer.findById(id)
      expect(instClass.name).toEqual('john smith')
      expect(instClass.age).toEqual(29)
 
    it 'should destroy an instance', ->
      instClass = Test.Customer.initInstance
        name: 'Tom Cully'
        age: 33
      id = instClass.id
      instClass.save()
      expect(Test.Customer.exists(id)).toBeTruthy()

      instClass.destroy()
      
      expect(Test.Customer.exists(id)).toBeFalsy()
      expect(Test.Customer.findById(id)).not.toBeDefined()

  describe 'Mozart.Model relations', ->
    describe 'belongsTo', ->
      beforeEach ->
        Test.Cat = Mozart.Model.create({ modelName: 'Cat' })
        Test.Cat.attributes
          name: 'string'
          breed: 'string'

        Test.Customer = Mozart.Model.create({ modelName: 'Customer' })
        Test.Customer.attributes
          name: 'string'
          age: 'integer'
        Test.Customer.belongsTo Test.Cat, 'pet'

      it 'should create relation field automatically', ->
        expect(_(Test.Customer.attrs).keys()).toContain('pet_id')

      it 'has correct foreign keys', ->
        expect(_(Test.Customer.fks).keys()).toContain('pet_id')
        expect(Test.Customer.fks['pet_id']).toBe(Test.Cat)

      it 'should allow the relation to be null', ->
        tom = Test.Customer.initInstance
          name: 'Tom'
          age: '35'
        tom.save()
        
        expect(tom.get("pet")).toBeNull()

      it 'should allow the relation to be set', ->
        tom = Test.Customer.initInstance
          name: 'Tom'
          age: '35'
        tom.save()

        ginger = Test.Cat.initInstance
          name: 'Ginger'
          age: 10
        ginger.save()

        tom.set("pet",ginger)
        
        expect(tom.get("pet")).toBe(ginger)

      it 'should allow the relation to be reset', ->
        tom = Test.Customer.initInstance
          name: 'Tom'
          age: '35'
        tom.save()

        ginger = Test.Cat.initInstance
          name: 'Ginger'
          age: 21
        ginger.save()

        jonny = Test.Customer.initInstance
          name: 'Jonny'
          age: '29'
        jonny.save()

        lee = Test.Cat.initInstance
          name: 'Lee'
          age: 10
        lee.save()

        jonny.set('pet',lee)
        tom.pet(ginger)
        expect(tom.get('pet')).toBe(ginger)
        expect(tom.pet_id).toEqual(ginger.id)
        tom.set('pet',null)
        expect(tom.get('pet')).toBeNull()
        expect(jonny.get('pet')).toBe(lee)
        expect(jonny.pet_id).toEqual(lee.id)

    describe 'belongsToPoly', ->
      beforeEach ->
        Test.Dog = Mozart.Model.create({ modelName: 'Dog' })
        Test.Dog.attributes
          name: 'string'
          breed: 'string'

        Test.Cat = Mozart.Model.create({ modelName: 'Cat' })
        Test.Cat.attributes
          name: 'string'
          has_collar: 'boolean'

        Test.Customer = Mozart.Model.create({ modelName: 'Customer' })
        Test.Customer.attributes
          name: 'string'
          age: 'integer'
        Test.Customer.belongsToPoly [Test.Dog, Test.Cat], 'pet'

        @tom = Test.Customer.initInstance
          name: 'Tom'
          age: '35'
        @tom.save()

        @ruadh = Test.Dog.initInstance
          name: 'Ruadh'
          breed: 'Irish Setter'
        @ruadh.save()

        @ginger = Test.Cat.initInstance
          name: 'Ginger'
          has_collar: true
        @ginger.save()

      it 'should setup the correct fields', ->
        expect(Test.Customer.attrs['pet_id']).toEqual('integer')
        expect(Test.Customer.attrs['pet_type']).toEqual('string')
        expect(Test.Customer.polyFks['pet_id']).toEqual('pet_type')

      it 'should allow assignment', ->
        @tom.pet(@ruadh)

        expect(@tom.pet_id).toEqual(@ruadh.id)
        expect(@tom.pet_type).toEqual(@ruadh.modelClass.modelName)
        expect(@tom.get('pet')).toEqual(@ruadh)

      it 'should allow assignment then null assignment', ->
        @tom.pet(@ruadh)

        @tom.pet(null)

        expect(@tom.pet_id).toBeNull()
        expect(@tom.pet_type).toBeNull()
        expect(@tom.get('pet')).toBeNull()

      it 'should allow assignment then reassignment', ->
        @tom.pet(@ruadh)
        @tom.pet(@ginger)

        expect(@tom.pet_id).toEqual(@ginger.id)
        expect(@tom.pet_type).toEqual(@ginger.modelClass.modelName)
        expect(@tom.get('pet')).toEqual(@ginger)

      it 'should remove fk and type on other model delete', ->
        @tom.pet(@ginger)

        expect(@tom.pet_id).toEqual(@ginger.id)
        expect(@tom.pet_type).toEqual(@ginger.modelClass.modelName)
        expect(@tom.get('pet')).toEqual(@ginger)

        @ginger.destroy()

        expect(@tom.pet_id).toBeNull()
        expect(@tom.pet_type).toBeNull()
        expect(@tom.get('pet')).toBeNull()

    describe 'hasOne', ->
      beforeEach ->
        Test.Account = Mozart.Model.create({ modelName: 'Account' })
        Test.Account.attributes
          number: 'string'

        Test.Customer = Mozart.Model.create({ modelName: 'Customer' })
        Test.Customer.attributes
          name: 'string'

        Test.Customer.hasOne Test.Account, 'account', 'customer_id'

        @tom = Test.Customer.initInstance
          name: 'Tom'
        @tom.save()

        @john = Test.Customer.initInstance
          name: 'Tom'
        @john.save()

        @kiwibank = Test.Account.initInstance
          number: '23874872384'
        @kiwibank.save()

        @asb = Test.Account.initInstance
          number: '234234234234'
        @asb.save()

      it "should allow the relation to be set", ->
        @tom.account(@kiwibank)

        expect(@kiwibank.customer_id).toEqual(@tom.id)
        expect(@tom.account().id).toEqual(@kiwibank.id)

      it "should allow the relation to be reset", ->
        @tom.account(@kiwibank)
        @tom.account(null)
        expect(@kiwibank.customer_id).toBeNull()
        expect(@tom.account()).toBeNull()

      it "should allow only one record to point to it", ->
        @tom.account(@kiwibank)
        @tom.account(@asb)
        expect(@kiwibank.customer_id).toBeNull()
        expect(@asb.customer_id).toEqual(@tom.id)
        expect(@tom.account().id).toEqual(@asb.id)

    describe 'hasMany', ->
      beforeEach ->
        Test.Dog = Mozart.Model.create({ modelName: 'Dog' })
        Test.Dog.attributes
          name: 'string'
          breed: 'string'

        Test.Customer = Mozart.Model.create({ modelName: 'Customer' })
        Test.Customer.attributes
          name: 'string'
          age: 'integer'
        Test.Customer.hasMany Test.Dog, 'pets'

        @tom = Test.Customer.initInstance
          name: 'Tom'
          age: '28'
        @tom.save()

        @oscar = Test.Dog.initInstance
          name: 'Oscar'
          age: '1'
        @oscar.save()

        @connor = Test.Dog.initInstance
          name: 'Connor'
          age: '8'
        @connor.save()

        @ruadh = Test.Dog.initInstance
          name: 'Ruadh'
          age: '10'
        @ruadh.save()

      it 'should return the same collection singleton twice', ->
        x = @tom.get('pets')
        expect(@tom.get('pets')).toBe(x)

      it 'should create relation field automatically', ->
        expect(_(Test.Dog.attrs).keys()).toContain('customer_id')
        
      it 'has correct foreign keys', ->
        expect(_(Test.Dog.fks).keys()).toContain('customer_id')
        expect(Test.Dog.fks['customer_id']).toBe(Test.Customer)

      it 'should return empty collection on init', ->
        x = @tom.pets()
        expect(x.count()).toEqual(0)
        expect(x.all()).toEqual([])

      it 'should allow additions to the collection', ->
        x = @tom.get('pets')

        x.add(@ruadh)

        x = @tom.get('pets')
        expect(x.count()).toEqual(1)
        expect(x.all()).toEqual([@ruadh])

        x.add(@connor)

        x = @tom.get('pets')
        expect(x.count()).toEqual(2)
        l = x.all()
        expect(l).toContain(@ruadh)
        expect(l).toContain(@connor)
        expect(l).not.toContain(@oscar)

      it 'should allow removals from the collection', ->
        x = @tom.get('pets')
        x.add(@ruadh)
        x.add(@oscar)

        x = @tom.get('pets')
        x.remove(@ruadh)

        x = @tom.get('pets')
        expect(x.count()).toEqual(1)
        l = x.all()
        expect(l).not.toContain(@ruadh)
        expect(l).toContain(@oscar)
        expect(l).not.toContain(@connor)

      it 'should update when collection elements are deleted', ->
        x = @tom.get('pets')
        x.add(@ruadh)
        x.add(@connor)
        x.add(@oscar)
        @connor.destroy()

        x = @tom.get('pets')
        expect(x.count()).toEqual(2)
        l = x.all()
        expect(l).toContain(@ruadh)
        expect(l).not.toContain(@connor)
        expect(l).toContain(@oscar)

    describe 'hasManyPoly', ->
      beforeEach ->
        Test.Cat = Mozart.Model.create({ modelName: 'Cat' })
        Test.Cat.attributes
          name: 'string'
          age: 'integer'

        Test.Dog = Mozart.Model.create({ modelName: 'Dog' })
        Test.Dog.attributes
          name: 'string'
          breed: 'string'

        Test.Customer = Mozart.Model.create({ modelName: 'Customer' })
        Test.Customer.attributes
          name: 'string'

        Test.House = Mozart.Model.create({ modelName: 'House' })
        Test.House.attributes
          name: 'string'
          address: 'string'

        Test.Cat.hasManyPoly Test.Customer, 'owners', 'associated_id', 'associated_type'
        Test.Cat.hasManyPoly Test.House, 'houses', 'associated_id', 'associated_type'

        Test.Dog.hasManyPoly Test.Customer, 'owners', 'associated_id', 'associated_type'
        Test.Dog.hasManyPoly Test.House, 'houses', 'associated_id', 'associated_type'

        @lee = Test.Cat.initInstance
          name: 'Lee'
          age: '10'
        @lee.save()   

        @connor = Test.Dog.initInstance
          name: 'Connor'
          age: '4'
        @connor.save() 

        @tom = Test.Customer.initInstance
          name: 'Tom'
          age: '33'
        @tom.save()

        @jonny = Test.Customer.initInstance
          name: 'Jonny'
          age: '29'
        @jonny.save()

        @rockpile = Test.House.initInstance
          name: 'Rockpile'
          address: 'Princetown Road'
        @rockpile.save()

        @Smail = Test.House.initInstance
          name: 'Devhouse'
          address: '233 Smail Street'
        @Smail.save()

      it 'should create relation fields automatically on model', ->
        expect(_(Test.Customer.attrs).keys()).toContain('associated_id')
        expect(_(Test.Customer.attrs).keys()).toContain('associated_type')

        expect(_(Test.House.attrs).keys()).toContain('associated_id')
        expect(_(Test.House.attrs).keys()).toContain('associated_type')

      it 'should allow additions to the relation', ->
        @lee.owners().add(@tom)
        @lee.owners().add(@jonny)
        @lee.houses().add(@rockpile)
        @connor.houses().add(@Smail)

        expect(@tom.associated_id).toEqual(@lee.id)
        expect(@tom.associated_type).toEqual(@lee.modelClass.modelName)

        expect(@rockpile.associated_id).toEqual(@lee.id)
        expect(@rockpile.associated_type).toEqual(@lee.modelClass.modelName)

        x = @lee.owners().all()
        expect(x.length).toEqual(2)
        expect(x).toContain(@tom)
        expect(x).toContain(@jonny)

        x = @lee.houses().all()
        expect(x.length).toEqual(1)
        expect(x).toContain(@rockpile)

        x = @connor.owners().all()
        expect(x.length).toEqual(0)

        x = @connor.houses().all()
        expect(x.length).toEqual(1)
        expect(x).toContain(@Smail)
         
      it 'should allow removal from the relation', ->
        @lee.owners().add(@tom)
        @lee.owners().add(@jonny)
        @lee.houses().add(@rockpile)
        @connor.houses().add(@Smail)

        @lee.owners().remove(@tom)

        x = @lee.owners().all()
        expect(x.length).toEqual(1)
        expect(x).toContain(@jonny)

        x = @lee.houses().all()
        expect(x.length).toEqual(1)
        expect(x).toContain(@rockpile)

        x = @connor.owners().all()
        expect(x.length).toEqual(0)

        x = @connor.houses().all()
        expect(x.length).toEqual(1)
        expect(x).toContain(@Smail)

      it 'should remove the relation when the foreign key object is deleted', ->
        @lee.owners().add(@tom)
        @lee.owners().add(@jonny)
        @lee.houses().add(@rockpile)
        @connor.houses().add(@Smail)

        @lee.destroy()

        expect(@tom.associated_id).toBeNull()
        expect(@tom.associated_type).toBeNull()

        expect(@jonny.associated_id).toBeNull()
        expect(@jonny.associated_type).toBeNull()

        expect(@rockpile.associated_id).toBeNull()
        expect(@rockpile.associated_type).toBeNull()

        x = @connor.owners().all()
        expect(x.length).toEqual(0)

        x = @connor.houses().all()
        expect(x.length).toEqual(1)
        expect(x).toContain(@Smail)

    describe 'hasManyThrough', ->
      beforeEach ->
        Test.Tag = Mozart.Model.create({ modelName: 'Tag' })
        Test.Tag.attributes
          name: 'string'

        Test.CustomerTag = Mozart.Model.create({ modelName: 'PersonTag' })

        Test.Customer = Mozart.Model.create({ modelName: 'Customer' })
        Test.Customer.attributes
          name: 'string'
          age: 'integer'
        Test.Customer.hasManyThrough Test.Tag, 'tags', Test.CustomerTag

        @coder = Test.Tag.initInstance
          name: 'Coder'
        @coder.save()

        @irish = Test.Tag.initInstance
          name: 'Irish'
        @irish.save()

        @aussie = Test.Tag.initInstance
          name: 'aussie'
        @aussie.save()

        @tom = Test.Customer.initInstance
          name: 'Tom'
          age: '33'
        @tom.save()

        @john = Test.Customer.initInstance
          name: 'john'
          age: '29'
        @john.save()

      it 'should return the same collection singleton twice per record', ->
        x = @tom.get('tags')
        y = @john.get('tags')
        expect(@tom.get('tags')).toBe(x)
        expect(@john.get('tags')).toBe(y)
        expect(x).not.toBe(y)

      it 'should create relation fields automatically on linkmodel', ->
        expect(_(Test.CustomerTag.attrs).keys()).toContain('customer_id')
        expect(_(Test.CustomerTag.attrs).keys()).toContain('tag_id')

      it 'has correct foreign keys on linkmodel', ->
        expect(_(Test.CustomerTag.fks).keys()).toContain('customer_id')
        expect(Test.CustomerTag.fks['customer_id']).toBe(Test.Customer)
        expect(_(Test.CustomerTag.fks).keys()).toContain('tag_id')
        expect(Test.CustomerTag.fks['tag_id']).toBe(Test.Tag)

      it 'should return an empty collection on init', ->
        expect(@tom.get('tags').all()).toEqual([])
        expect(@john.get('tags').all()).toEqual([])
        expect(@tom.get('tags').count()).toEqual(0)
        expect(@john.get('tags').count()).toEqual(0)
      
      it 'should allow additions to the collection', ->
        x = @tom.get('tags')
        x.add(@irish)
        x.add(@coder)

        x = @john.get('tags')
        x.add(@aussie)
        x.add(@coder)

        expect(Test.CustomerTag.all().length).toEqual(4)

        x = @tom.get('tags')
        expect(x.all().length).toEqual(2)
        expect(x.all()).not.toContain(@aussie)
        expect(x.all()).toContain(@irish)
        expect(x.all()).toContain(@coder)

        x = @john.get('tags')
        expect(x.all().length).toEqual(2)
        expect(x.all()).toContain(@aussie)
        expect(x.all()).not.toContain(@irish)
        expect(x.all()).toContain(@coder)

      it 'should allow removals from the collection', ->
        x = @tom.get('tags')
        x.add(@irish)
        x.add(@coder)

        x = @john.get('tags')
        x.add(@aussie)
        x.add(@coder)

        x = @tom.get('tags')
        x.remove(@irish)

      it 'should update when collection elements are deleted', ->
        x = @tom.get('tags')
        x.add(@irish)
        x.add(@coder)

        x = @john.get('tags')
        x.add(@aussie)
        x.add(@coder)

        expect(Test.CustomerTag.all().length).toEqual(4)

        @coder.destroy()

        expect(Test.CustomerTag.all().length).toEqual(2)

        x = @tom.get('tags')
        expect(x.all().length).toEqual(1)
        expect(x.all()).not.toContain(@aussie)
        expect(x.all()).toContain(@irish)
        expect(x.all()).not.toContain(@coder)
        
        x = @john.get('tags')
        expect(x.all().length).toEqual(1)
        expect(x.all()).toContain(@aussie)
        expect(x.all()).not.toContain(@irish)
        expect(x.all()).not.toContain(@coder)

    describe 'hasManyThroughPoly', ->
      beforeEach ->
        Test.Dog = Mozart.Model.create({ modelName: 'Dog' })
        Test.Dog.attributes
          name: 'string'
          registered: 'boolean'

        Test.Cat = Mozart.Model.create({ modelName: 'Cat' })
        Test.Cat.attributes
          name: 'string'
          whiskers: 'string'

        Test.CustomerPet = Mozart.Model.create({ modelName: 'PersonPet' })

        Test.Customer = Mozart.Model.create({ modelName: 'Customer' })
        Test.Customer.attributes
          name: 'string'
          age: 'integer'
        Test.Customer.hasManyThroughPoly Test.Dog, 'dogs', Test.CustomerPet, 'customer_id', 'pet_id', 'pet_type' 
        Test.Customer.hasManyThroughPoly Test.Cat, 'cats', Test.CustomerPet, 'customer_id', 'pet_id', 'pet_type' 

        @tom = Test.Customer.initInstance
          name: 'Tom'
          age: '28'
        @tom.save()

        @jonny = Test.Customer.initInstance
          name: 'Jonny'
          age: '28'
        @jonny.save()

        @ruadh = Test.Dog.initInstance
          name: 'Ruadh'
          age: '10'
        @ruadh.save()

        @connor = Test.Dog.initInstance
          name: 'Connor'
        @connor.save()

        @ginger = Test.Cat.initInstance
          name: 'Ginger'
        @ginger.save()

        @lee = Test.Cat.initInstance
          name: 'Lee'
        @lee.save()

      it 'should return the same collection singleton twice per record', ->
        x = @tom.get('dogs')
        y = @jonny.get('dogs')
        expect(@tom.get('dogs')).toBe(x)
        expect(@jonny.get('dogs')).toBe(y)
        expect(x).not.toBe(y)

      it 'should create relation fields automatically on linkmodel', ->
        expect(_(Test.CustomerPet.attrs).keys()).toContain('customer_id')
        expect(_(Test.CustomerPet.attrs).keys()).toContain('pet_type')
        expect(_(Test.CustomerPet.attrs).keys()).toContain('pet_id')

      it 'has correct foreign keys on linkmodel', ->
        expect(_(Test.CustomerPet.fks).keys()).toContain('customer_id')
        expect(Test.CustomerPet.fks['customer_id']).toBe(Test.Customer)
        expect(_(Test.CustomerPet.polyFks).keys()).toContain('pet_id')
        expect(Test.CustomerPet.polyFks['pet_id']).toEqual('pet_type')

      it 'should return empty collection on init', ->
        x = @tom.get('dogs')
        expect(x.count()).toEqual(0)
        expect(x.all()).toEqual([])
        x = @tom.get('dogs')
        expect(x.count()).toEqual(0)
        expect(x.all()).toEqual([])

      it 'should allow additions to the collection', ->

        @tom.get('dogs').add(@ruadh)
        @tom.get('cats').add(@ginger)
        @tom.get('cats').add(@lee)

        @jonny.get('dogs').add(@ruadh)
        @jonny.get('dogs').add(@connor)
        @jonny.get('cats').add(@lee)

        expect(Test.CustomerPet.all().length).toEqual(6)

        x = @tom.get('dogs')
        expect(x.count()).toEqual(1)
        expect(x.all()).toEqual([@ruadh])

        x = @tom.get('cats')
        expect(x.count()).toEqual(2)
        expect(x.contains(@ginger)).toBeTruthy()
        expect(x.contains(@lee)).toBeTruthy()

        x = @jonny.get('dogs')
        expect(x.count()).toEqual(2)
        expect(x.all()).toContain(@ruadh)
        expect(x.all()).toContain(@connor)

        x = @jonny.get('cats')
        expect(x.count()).toEqual(1)
        expect(x.all()).toContain(@lee)

      it 'should allow removals from the collection', ->
        @tom.get('dogs').add(@ruadh)
        @tom.get('cats').add(@ginger)
        @tom.get('cats').add(@lee)

        @jonny.get('dogs').add(@ruadh)
        @jonny.get('dogs').add(@connor)
        @jonny.get('cats').add(@lee)

        @tom.get('cats').remove(@ginger)
        @jonny.get('dogs').remove(@connor)

        expect(Test.CustomerPet.all().length).toEqual(4)

        x = @tom.get('dogs')
        expect(x.count()).toEqual(1)
        expect(x.all()).toEqual([@ruadh])

        x = @tom.get('cats')
        expect(x.count()).toEqual(1)
        expect(x.contains(@lee)).toBeTruthy()

        x = @jonny.get('dogs')
        expect(x.count()).toEqual(1)
        expect(x.all()).toContain(@ruadh)

        x = @jonny.get('cats')
        expect(x.count()).toEqual(1)
        expect(x.all()).toContain(@lee)

      it 'should update when collection elements are deleted', ->
        @tom.get('dogs').add(@ruadh)
        @tom.get('cats').add(@ginger)
        @tom.get('cats').add(@lee)

        @jonny.get('dogs').add(@ruadh)
        @jonny.get('dogs').add(@connor)
        @jonny.get('cats').add(@lee)

        @connor.destroy()
        @lee.destroy()

        expect(Test.CustomerPet.all().length).toEqual(3)

        x = @tom.get('dogs')
        expect(x.count()).toEqual(1)
        expect(x.all()).toEqual([@ruadh])

        x = @tom.get('cats')
        expect(x.count()).toEqual(1)
        expect(x.contains(@ginger)).toBeTruthy()

        x = @jonny.get('dogs')
        expect(x.count()).toEqual(1)
        expect(x.all()).toContain(@ruadh)

        x = @jonny.get('cats')
        expect(x.count()).toEqual(0)

      it 'should update when entities are deleted', ->
        @tom.get('dogs').add(@ruadh)
        @tom.get('cats').add(@ginger)
        @tom.get('cats').add(@lee)

        @jonny.get('dogs').add(@ruadh)
        @jonny.get('dogs').add(@connor)
        @jonny.get('cats').add(@lee)

        @tom.destroy()

        expect(Test.CustomerPet.all().length).toEqual(3)

        x = @jonny.get('dogs')
        expect(x.count()).toEqual(2)
        expect(x.all()).toContain(@ruadh)
        expect(x.all()).toContain(@connor)

        x = @jonny.get('cats')
        expect(x.count()).toEqual(1)
        expect(x.all()).toContain(@lee)

    describe 'hasManyThroughPolyReverse', ->
      beforeEach ->
        Test.Dog = Mozart.Model.create({ modelName: 'Dog' })
        Test.Dog.attributes
          name: 'string'
          registered: 'boolean'

        Test.Cat = Mozart.Model.create({ modelName: 'Cat' })
        Test.Cat.attributes
          name: 'string'
          whiskers: 'string'

        Test.CustomerPet = Mozart.Model.create({ modelName: 'PersonPet' })

        Test.Customer = Mozart.Model.create({ modelName: 'Customer' })
        Test.Customer.attributes
          name: 'string'
          age: 'integer'
        Test.Customer.hasManyThroughPoly Test.Dog, 'dogs', Test.CustomerPet, 'customer_id', 'pet_id', 'pet_type' 
        Test.Customer.hasManyThroughPoly Test.Cat, 'cats', Test.CustomerPet, 'customer_id', 'pet_id', 'pet_type' 

        # hasManyThroughPolyReverse needs a existing hasManyThroughPoly.

        Test.Dog.hasManyThroughPolyReverse Test.Customer, 'owners', Test.CustomerPet, 'customer_id', 'pet_id', 'pet_type' 
        Test.Cat.hasManyThroughPolyReverse Test.Customer, 'owners', Test.CustomerPet, 'customer_id', 'pet_id', 'pet_type' 
        
        @tom = Test.Customer.initInstance
          name: 'Tom'
          age: '28'
        @tom.save()

        @jonny = Test.Customer.initInstance
          name: 'Jonny'
          age: '28'
        @jonny.save()

        @ruadh = Test.Dog.initInstance
          name: 'Ruadh'
          age: '10'
        @ruadh.save()

        @connor = Test.Dog.initInstance
          name: 'Connor'
        @connor.save()

        @ginger = Test.Cat.initInstance
          name: 'Ginger'
        @ginger.save()

        @lee = Test.Cat.initInstance
          name: 'Lee'
        @lee.save()

      it 'should return the same collection singleton twice per record', ->
        x = @ruadh.get('owners')
        y = @ginger.get('owners')
        expect(@ruadh.get('owners')).toBe(x)
        expect(@ginger.get('owners')).toBe(y)
        expect(x).not.toBe(y)

      it 'should create relation fields automatically on linkmodel', ->
        expect(_(Test.CustomerPet.attrs).keys()).toContain('customer_id')
        expect(_(Test.CustomerPet.attrs).keys()).toContain('pet_type')
        expect(_(Test.CustomerPet.attrs).keys()).toContain('pet_id')

      it 'has correct foreign keys on linkmodel', ->
        expect(_(Test.CustomerPet.fks).keys()).toContain('customer_id')
        expect(Test.CustomerPet.fks['customer_id']).toBe(Test.Customer)
        expect(_(Test.CustomerPet.polyFks).keys()).toContain('pet_id')
        expect(Test.CustomerPet.polyFks['pet_id']).toEqual('pet_type')

      it 'should return empty collection on init', ->
        x = @connor.get('owners')
        expect(x.count()).toEqual(0)
        expect(x.all()).toEqual([])
        x = @ginger.get('owners')
        expect(x.count()).toEqual(0)
        expect(x.all()).toEqual([])

      it 'should allow additions to the collection', ->

        @connor.get('owners').add(@tom)
        @connor.get('owners').add(@jonny)

        @ginger.get('owners').add(@tom)

        expect(Test.CustomerPet.all().length).toEqual(3)

        x = @connor.get('owners')
        expect(x.count()).toEqual(2)
        expect(x.all()).toContain(@tom)
        expect(x.all()).toContain(@jonny)

        x = @ginger.get('owners')
        expect(x.count()).toEqual(1)
        expect(x.all()).toEqual([@tom])

      it 'should allow removals from the collection', ->
        @connor.get('owners').add(@tom)
        @connor.get('owners').add(@jonny)

        @ginger.get('owners').add(@tom)

        @connor.get('owners').remove(@tom)
        @ginger.get('owners').remove(@tom)

        expect(Test.CustomerPet.all().length).toEqual(1)

        x = @connor.get('owners')
        expect(x.count()).toEqual(1)
        expect(x.all()).toEqual([@jonny])
        expect(x.contains(@jonny)).toBeTruthy()

        x = @ginger.get('owners')
        expect(x.count()).toEqual(0)

      it 'should update when collection elements are deleted', ->
        @connor.get('owners').add(@tom)

        @ginger.get('owners').add(@tom)
        @ginger.get('owners').add(@jonny)

        @tom.destroy()

        expect(Test.CustomerPet.all().length).toEqual(1)

        x = @connor.get('owners')
        expect(x.count()).toEqual(0)

        x = @ginger.get('owners')
        expect(x.count()).toEqual(1)
        expect(x.contains(@jonny)).toBeTruthy()

    describe 'relations work on modelinstances that are not yet created', ->
      beforeEach ->

        Test.Tag = Mozart.Model.create({ modelName: 'Tag' })
        Test.Tag.attributes
          name: 'string'

        Test.Basket = Mozart.Model.create({ modelName: 'Basket' })
        Test.Basket.attributes
          name: 'string'

        Test.Cat = Mozart.Model.create({ modelName: 'Cat' })
        Test.Cat.attributes
          name: 'string'
        Test.Cat.belongsTo Test.Basket, 'basket'

        Test.CustomerTag = Mozart.Model.create({ modelName: 'PersonTag' })

        Test.Customer = Mozart.Model.create({ modelName: 'Customer' })
        Test.Customer.attributes
          name: 'string'
          age: 'integer'
        Test.Customer.hasMany Test.Cat, 'cats',
        Test.Customer.hasManyThrough Test.Tag, 'tags', Test.CustomerTag

        @tom = Test.Customer.initInstance
          name: 'Tom'
          age: '33'

        @john = Test.Customer.initInstance
          name: 'john'
          age: '29'

        @coder = Test.Tag.initInstance
          name: 'Coder'

        @irish = Test.Tag.initInstance
          name: 'Irish'

        @aussie = Test.Tag.initInstance
          name: 'aussie'

        @lee = Test.Cat.initInstance
          name: 'Lee'

        @basket = Test.Basket.initInstance
          name: 'Green Basket'

  describe "Mozart.Model indexing", ->
    describe "Map Index", ->
      beforeEach ->
        Test.Tag = Mozart.Model.create({ modelName: 'Tag' })
        Test.Tag.attributes
          name: 'string'
        Test.Tag.index 'name', 'map'

        @coder = Test.Tag.initInstance
          name: 'Coder'
        @coder.save()

        @coder2 = Test.Tag.initInstance
          name: 'Coder'
        @coder2.save()

        @irish = Test.Tag.initInstance
          name: 'Irish'
        @irish.save()

        @aussie = Test.Tag.initInstance
          name: 'aussie'
        @aussie.save()

        @internalMap = Test.Tag.indexes['name'].map

      it 'should build an index correctly', ->
        expect(@internalMap).toBeDefined()
        expect(_(@internalMap).keys().length).toEqual(3)
        expect(@internalMap['Coder']).toBeDefined()
        expect(@internalMap['Irish']).toBeDefined()
        expect(@internalMap['aussie']).toBeDefined()
        expect(_(@internalMap['Coder']).keys().length).toEqual(2)
        expect(@internalMap['Coder'][@coder.id]).toEqual(@coder)
        expect(@internalMap['Coder'][@coder2.id]).toEqual(@coder2)
        expect(_(@internalMap['Irish']).keys().length).toEqual(1)
        expect(@internalMap['Irish'][@irish.id]).toEqual(@irish)
        expect(_(@internalMap['aussie']).keys().length).toEqual(1)
        expect(@internalMap['aussie'][@aussie.id]).toEqual(@aussie)

      it 'should move the record in the index when a value changes to another existing value', ->

        @coder2.set('name', 'aussie')

        expect(_(@internalMap['Coder']).keys().length).toEqual(1)
        expect(@internalMap['Coder'][@coder.id]).toEqual(@coder)
        expect(_(@internalMap['Irish']).keys().length).toEqual(1)
        expect(@internalMap['Irish'][@irish.id]).toEqual(@irish)
        expect(_(@internalMap['aussie']).keys().length).toEqual(2)
        expect(@internalMap['aussie'][@aussie.id]).toEqual(@aussie)
        expect(@internalMap['aussie'][@coder2.id]).toEqual(@coder2)

      it 'should create a value in the index when a value changes to new value', ->

        @coder2.set('name', 'Sod')

        expect(@internalMap['Sod']).toBeDefined()

        expect(_(@internalMap['Coder']).keys().length).toEqual(1)
        expect(@internalMap['Coder'][@coder.id]).toEqual(@coder)
        expect(_(@internalMap['Irish']).keys().length).toEqual(1)
        expect(@internalMap['Irish'][@irish.id]).toEqual(@irish)
        expect(_(@internalMap['aussie']).keys().length).toEqual(1)
        expect(@internalMap['aussie'][@aussie.id]).toEqual(@aussie)
        expect(_(@internalMap['Sod']).keys().length).toEqual(1)
        expect(@internalMap['Sod'][@coder2.id]).toEqual(@coder2)

      it 'should remove the index oldvalue when a record changes to another existing value leaving the old index value empty', ->

        @irish.set('name','Coder')

        expect(_(@internalMap).keys().length).toEqual(2)
        expect(@internalMap['Irish']).not.toBeDefined()

        expect(_(@internalMap['Coder']).keys().length).toEqual(3)
        expect(@internalMap['Coder'][@coder.id]).toEqual(@coder)
        expect(@internalMap['Coder'][@coder2.id]).toEqual(@coder2)
        expect(@internalMap['Coder'][@irish.id]).toEqual(@irish)
        expect(_(@internalMap['aussie']).keys().length).toEqual(1)
        expect(@internalMap['aussie'][@aussie.id]).toEqual(@aussie)

      it 'should update the index when a record is destroyed', ->

        @aussie.destroy()

        expect(_(@internalMap).keys().length).toEqual(2)
        expect(@internalMap['Coder']).toBeDefined()
        expect(@internalMap['Irish']).toBeDefined()

      it 'should empty all records on model reset', ->
        Test.Tag.reset()

        expect(Test.Tag.indexes['name'].map).toBeDefined()
        expect(_(Test.Tag.indexes['name'].map).keys().length).toEqual(0)

    describe 'Boolean Index', ->
      beforeEach ->
        Test.Tag = Mozart.Model.create({ modelName: 'Tag' })
        Test.Tag.attributes
          name: 'string'
          deleted_at: 'datetime'

        Test.Tag.index 'deleted_at', 'boolean', { value: null }

        @coder = Test.Tag.initInstance
          name: 'Coder'
          deleted_at :null
        @coder.save()

        @coder2 = Test.Tag.initInstance
          name: 'Coder'
          deleted_at: new Date().setDate(1)
        @coder2.save()

        @irish = Test.Tag.initInstance
          name: 'Irish'
          deleted_at :null
        @irish.save()

        @aussie = Test.Tag.initInstance
          name: 'aussie'
          deleted_at: new Date().setDate(2)
        @aussie.save()

        @internal = Test.Tag.indexes['deleted_at']

      it 'should properly define the index', ->
        expect(@internal).toBeDefined()
        expect(_(@internal.valueIds).keys().length).toEqual(2)
        expect(@internal.valueIds[@coder.id]).toEqual(@coder)
        expect(@internal.valueIds[@irish.id]).toEqual(@irish)
        expect(_(@internal.nonValueIds).keys().length).toEqual(2)
        expect(@internal.nonValueIds[@coder2.id]).toEqual(@coder2)
        expect(@internal.nonValueIds[@aussie.id]).toEqual(@aussie)

      it 'should move the record in the index when a value changes', ->
        @coder.set('deleted_at',new Date().setDate(3))

        expect(_(@internal.valueIds).keys().length).toEqual(1)
        expect(@internal.valueIds[@irish.id]).toEqual(@irish)
        expect(_(@internal.nonValueIds).keys().length).toEqual(3)
        expect(@internal.nonValueIds[@coder.id]).toEqual(@coder)
        expect(@internal.nonValueIds[@coder2.id]).toEqual(@coder2)
        expect(@internal.nonValueIds[@aussie.id]).toEqual(@aussie)

        @coder2.set('deleted_at',null)

        expect(_(@internal.valueIds).keys().length).toEqual(2)
        expect(@internal.valueIds[@irish.id]).toEqual(@irish)
        expect(@internal.valueIds[@coder2.id]).toEqual(@coder2)
        expect(_(@internal.nonValueIds).keys().length).toEqual(2)
        expect(@internal.nonValueIds[@coder.id]).toEqual(@coder)
        expect(@internal.nonValueIds[@aussie.id]).toEqual(@aussie)

      it 'should add to the index when a new record is created', ->
        testnew = Test.Tag.initInstance
          name: 'testnew'
          deleted_at :null
        testnew.save()

        expect(@internal).toBeDefined()
        expect(_(@internal.valueIds).keys().length).toEqual(3)
        expect(@internal.valueIds[@coder.id]).toEqual(@coder)
        expect(@internal.valueIds[@irish.id]).toEqual(@irish)
        expect(@internal.valueIds[testnew.id]).toEqual(testnew)
        expect(_(@internal.nonValueIds).keys().length).toEqual(2)
        expect(@internal.nonValueIds[@coder2.id]).toEqual(@coder2)
        expect(@internal.nonValueIds[@aussie.id]).toEqual(@aussie)

      it 'should remove from the index when a record is destroyed', ->
        @aussie.destroy()

        expect(@internal).toBeDefined()
        expect(_(@internal.valueIds).keys().length).toEqual(2)
        expect(@internal.valueIds[@coder.id]).toEqual(@coder)
        expect(@internal.valueIds[@irish.id]).toEqual(@irish)
        expect(_(@internal.nonValueIds).keys().length).toEqual(1)
        expect(@internal.nonValueIds[@coder2.id]).toEqual(@coder2)

      it 'should empty all records on model reset', ->
        Test.Tag.reset()
        expect(_(Test.Tag.indexes['deleted_at'].valueIds).keys().length).toEqual(0)
        expect(_(Test.Tag.indexes['deleted_at'].nonValueIds).keys().length).toEqual(0)