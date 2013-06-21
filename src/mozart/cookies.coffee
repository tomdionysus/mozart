{MztObject} = require './object'

exports.Cookies = class Cookies extends MztObject

  @setCookie: (name, value, options) ->
    options = options or {}
    unless document.cookie == undefined

      # Set defaults
      options["path"] = "/" unless !!options["path"]

      # Build the cookie string components
      nameValue = "#{encodeURIComponent(name)}=#{encodeURIComponent(value)}"

      path =  if options["path"] then ";path=#{options["path"]}" else ""
      domain =  if options["domain"] then ";domain=#{options["domain"]}" else ""
      maxAge =  if options["max-age"] then ";max-age=#{options["max-age"]}" else ""

      expires = ""
      if options["expires"] instanceof Date
        expires = ";expires=#{options["expires"].toUTCString()}"

      secure = if options["secure"] then ";secure" else ""

      # Set the cookie
      document.cookie = nameValue + path + domain + maxAge + expires + secure

    this

  @getCookie: (name) ->
    cookies = document.cookie.split /;\s*/
    for cookie in cookies
      currentParts = cookie.split "="
      currentName = decodeURIComponent(currentParts[0])
      if currentName == name
        return decodeURIComponent(currentParts[1])
    return null

  @removeCookie: (name) ->
    date = new Date()
    date.setTime(date.getTime() - 1)
    @setCookie name, '',
      expires: date
    this

  @hasCookie: (name) ->
    @getCookie(name) != null
