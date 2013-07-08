{View} = require './view'
Util = require './util'

exports.I18nView = class I18nView extends View
  tag: 'span'
  idPrefix: 'i18nview'

  init: ->
    super
    throw new Error "Mozart.I18nView must have a i18nTemplate" unless @i18nTemplate?
    @subscribe 'change', @redraw

  templateFunction: ->
    try
      Util.getPath(window, "i18n.#{@i18nTemplate}")(@)
    catch err
      Util.warn 'MessageFormat failed with Error:', err
      ''
