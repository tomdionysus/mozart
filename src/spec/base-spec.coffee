beforeEach ->
  Test.oldConsole = window.console

  window.console = 
    log: ->
    warn: ->
    error: ->

afterEach ->
  window.console = Test.oldConsole