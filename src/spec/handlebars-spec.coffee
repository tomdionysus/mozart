Test = {}

Test.Hotel = Mozart.Model.create({ modelName: 'Hotel' })
Test.Hotel.attributes
  name: 'string'
  address: 'string'
  phoneno: 'string'

# Mozart.Handlebars spec
describe 'Mozart-handlebars', ->
  describe 'helper: collection', ->
    beforeEach ->
      Test.Hotel.reset()
      #App.layout.resetViews()

  describe 'helper: view', ->
    beforeEach ->
      class Test.TestView extends Mozart.View
        templateFunction: Handlebars.compile('<p>Hotels In Your Area:</p>
<ul>{{#each this}}
  <li>
  <h2>{{name}}</h2>
  <p>{{address}}, {{phoneno}}</p>
  </li>{{/each}}
</ul>')

      @testdata = {
        one: 1
        two: [
          'three',
          'four'
        ]
      }