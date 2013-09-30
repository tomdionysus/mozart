{View} = require './view'

# SwitchView is a View that can switch its Handlebars template depending on a value of
# an attribute in its content object
class SwitchView extends View

  # Switch the template by looking up @templateBase+"/"+@content[@templateField] in
  # the window.HandlebarsTemplates global and setting templateFunction to that compiled
  # handlebars function
  beforeRender: =>
    template = HandlebarsTemplates[@templateBase+"/"+@content[@templateField]]
    if template?
      @templateFunction = template
    else
      Util.warn("SwitchView view not found for "+@templateBase+"/"+@content[@templateField], @)
      @templateFunction = -> ''

exports.SwitchView = SwitchView