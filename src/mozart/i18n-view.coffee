{View} = require './view'
Util = require './util'

# An internationalized bound view. I18nView is used by the i18nBind handlebars helper.
class I18nView extends View
  tag: 'span'
  idPrefix: 'i18nview'

  # Initialise the view, checking i18nTemplate and subscribing to redraw on all changes.
  init: ->
    super
    Util.warn "I18nView must have an i18nTemplate", @ unless @i18nTemplate?
    @subscribe 'change', @redraw

  # The templateFunction calls the associated i18nTemplate in the window.i18n namespace
  templateFunction: ->
    try
      Util.getPath(window, "i18n.#{@i18nTemplate}")(@)
    catch err
      Util.warn 'MessageFormat failed with Error:', err
      ''
      
exports.I18nView = I18nView
