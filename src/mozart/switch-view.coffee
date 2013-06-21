{View} = require './view'

exports.SwitchView = class SwitchView extends View
  beforeRender: =>
    template = HandlebarsTemplates[@templateBase+"/"+@content[@templateField]]
    if template?
      @templateFunction = template
    else
      Util.log("views","SwitchView: No view found for "+@templateBase+"/"+@content[@templateField])
      @templateFunction = -> ''