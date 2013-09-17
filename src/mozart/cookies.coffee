{MztObject} = require './object'

# The Cookies class is an interface to browser cookies.
class Cookies extends MztObject

  # Set a value in the cookie
  # @param [string] The name of the cookie
  # @param [variant] The value of the cookie
  # @param [object] A map of options for the cookie, e.g. [date] 'expires'
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

  # Get a value from the cookie
  # @param [string] The name of the cookie
  # @return [variant] The value of the cookie
  @getCookie: (name) ->
    cookies = document.cookie.split /;\s*/
    for cookie in cookies
      currentParts = cookie.split "="
      currentName = decodeURIComponent(currentParts[0])
      if currentName == name
        return decodeURIComponent(currentParts[1])
    return null

  # Remove the cookie with the given name
  # @param [string] The name of the cookie
  @removeCookie: (name) ->
    date = new Date()
    date.setTime(date.getTime() - 1)
    @setCookie name, '',
      expires: date
    this

  # Check if a given cookie exists
  # @param [string] The name of the cookie
  # @return [boolean] Returns true if the cookie exists.
  @hasCookie: (name) ->
    @getCookie(name) != null

exports.Cookies = Cookies
