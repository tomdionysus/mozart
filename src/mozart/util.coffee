_logging = {}
_idCounter = 0

Util = module.exports =
  toString: Object.prototype.toString

  # Get the type of an argument as a string
  # @param [variant] object
  # @return [string] The type of the object: 'Object','Function','Array','String','Boolean'
  getType: (object) ->
    @toString.call(object).match(/^\[object\s(.*)\]$/)[1]

  # Find if the argument is an Object
  # @param [variant] object
  # @return [boolean] Return true if the argument is an object
  isObject: (object) ->
    @getType(object) is 'Object'

  # Find if the argument is a function
  # @param [variant] object
  # @return [boolean] Return true if the argument is a function
  isFunction: (object) ->
    @getType(object) is 'Function'

  # Find if the argument is an array
  # @param [variant] object
  # @return [boolean] Return true if the argument is an array
  isArray: (object) ->
    @getType(object) is 'Array'

  # Find if the argument is a string
  # @param [variant] object
  # @return [boolean] Return true if the argument is a string
  isString: (object) ->
    @getType(object) is 'String'

  # Find if the argument is an boolean
  # @param [variant] object
  # @return [boolean] Return true if the argument is an boolean
  isBoolean: (object) ->
    @getType(object) is 'Boolean'

  # Log with a specific stream type and arguments to the console,
  # if logging is enabled for that stream.
  # @param [string] type The stream bane
  # @param [variant] attrs Log Attributes
  log: (type, attrs...) ->
    console.log type + ":", attrs... if _logging[type]? and console?

  # Enable a specified log stream
  # @param [string] type The stream name to enable
  showLog: (type) ->
    _logging[type] = true

  # Disable a specified log stream
  # @param [string] type The stream name to disable
  hideLog: (type) ->
    _logging[type] = false

  # Log a console error if the console is available and throw an exception
  # @param [string] path The message
  # @param [variant] attrs Error Attributes
  error: (message, attrs...) ->
    console.error("Exception:", message, attrs) if console?
    throw message

  # Log a console warning if the console is available
  # @param [string] path The message
  # @param [variant] attrs Warning Attributes
  warn: (message, attrs...) ->
    console.log("Warning:", message, attrs) if console?

  # Clone an object
  # @param [object] obj The object to clone
  # @return [object] Returns a new shallow clone of the object
  clone: (obj) ->
    $.extend({}, obj)

  # Get the object at the specified path, throwing an error if any component of the 
  # path does not exist
  # @param [object] context The context to begin from
  # @param [string] path The path
  # @return [variant] The value of the property at context[path]

  getPath: (context, path) ->
    value = @_getPath(context, path)
    throw new Error "Object #{context} has no #{path}" if value is undefined
    value

  # Find if a path is an absolute path (First character is uppercase)
  # @param [string] path The path
  # @return [boolean] Returns true if the path is absolute
  isAbsolutePath: (path) ->
    path[0].toUpperCase() == path[0]

  # Find the value of the specifed path starting from the given context, or 
  # Mozart.root
  # @param [object] context The context to begin from
  # @param [string] path The path
  # @return [variant] The value of the property at context[path], or undefined if part of the path does not exist.
  _getPath: (context, path) ->
    if context? and not path?
      path = context
      context = Mozart.root

    context = Mozart.root if Util.isAbsolutePath(path)

    properties = path.split('.')
    while (properties.length > 0)
      property = properties.shift()
      unless property == 'this'
        return undefined if context[property] is undefined

        if Util.isFunction(context.get)
          value = context.get.call(context, property)
        else
          value = context[property]

        # detect intermediate null value in path (attempting to traverse a null value)
        return undefined if value is null and properties.length > 0
      else
        value = context
      context = value
    value

  # increment and Get a unique id from the global counter
  # @return [integer] A gloablly unique id
  getId: ->
    ++_idCounter

  # Parse the specified path into a target path and property
  # @param [string] path The path to parse
  # @return [array] A two element array of [ targetPath, propertyName ]
  parsePath: (path) ->
    if path.indexOf('.') == -1
      return [ null, path ]
    props = path.split('.')
    lastprop = props.pop()
    [ props.join('.'), lastprop ]

  # Create a map from an array of objects, given the array and an id field name
  # @param [array] itemArray The array of objects to parse
  # @param [string] idfield (optional) The id field in the objects, default 'id'
  # @return [object] A map of id -> object
  toMap: (itemArray, idfield = 'id') ->
    map = {}
    for item in itemArray
      map[item[idfield]] = item
    map

  # Sort an array in place with a parseSort sort query
  # @param [array] sortArray The array of objects to sort
  # @param [string] fields A parseSort sort string
  sortBy: (sortArray, fields) ->
    fields = Util.parseSort(fields)
    sortArray.sort((a, b) ->
      for field in fields
        if typeof a[field] == 'function'
          av = a[field]()
        else
          av = a[field]
        if typeof b[field] == 'function'
          bv = b[field]()
        else
          bv = b[field]
        if (av? and bv?)
          unless av?
            return -1
          unless bv?
            return 1
          av = av.toString().toLowerCase()
          bv = bv.toString().toLowerCase()
          if av > bv
            return 1
          else if av < bv
            return -1
    )

  # Parse a sort query string into an array of sort parameters
  # @param [string] str The string to parse
  # @param [object] state An internal parameter used in recursive sorts.
  # @return [array] An array of sort attributes, which may be nested.
  parseSort: (str, state) ->
    state ?= { pos: 0 }
    out = []
    current = ""
    while (state.pos < str.length)
      c = str[state.pos++]
      switch c
        when ','
          if current.length > 0
            out.push(current)
            current = ""
        when '['
          if current.length > 0
            throw new Error 'parseSort: Unexpected Character [ at ' + state.pos.toString()
          out.push(@parseSort(str, state))
        when ']'
          if current.length > 0
            out.push(current)
          return out
        else
          current += c
    if current.length > 0
      out.push(current)
      current = ""
    out

  # Get a CapsCase string from a snake_case name
  # @param [string] name The string to re-case
  # @return [string] The CapsCase string
  toCapsCase: (name) =>
    x = name.replace /^[a-z]{1,1}/g, (match) -> match.toUpperCase()
    x = x.replace /_[a-z]{1,1}/g, (match) -> match.toUpperCase()
    x = x.replace /_/g, " "
    x

  # Get a snake_case string from a CapsCase name
  # @param [string] name The string to re-case
  # @return [string] The snake_case string
  toSnakeCase: (name) =>
    x = name.replace /[A-Z]{1,1}/g, (match) =>
      "_" + match.toLowerCase()
    x.replace /^_/, ""

  # Return the portion of the given string before the token
  # @param [string] str The string to slice
  # @param [string] token The token suffix string
  # @return [string] The string before the token
  sliceStringBefore: (str, token) ->
    str.slice(0, str.length - token.length)

  # Return the portion of the given string after the token
  # @param [string] str The string to slice
  # @param [string] token The token prefix string
  # @return [string] The string after the token
  sliceStringAfter: (str, token) ->
    str.slice(token.length)

  # Find if a string ends with a given suffix token
  # @param [string] str The string to test
  # @param [string] token The token suffix string
  # @return [boolean] Return true if the string ends with the given token
  stringEndsWith: (str, token) ->
    len = token.length
    (str.length >= len) && (str.slice(-len) == token)

  # Find if a string begins with a given prefix token
  # @param [string] str The string to test
  # @param [string] token The token prefix string
  # @return [boolean] Return true if the string begins with the given token
  stringStartsWith: (str, token) ->
    len = token.length
    (str.length >= len) && (str.slice(0, len) == token)

  # Prefix all *Binding attribute values on the specified object with 'parent.'
  # @param [object] object The object on which to prefix *Binding attributes.
  addBindingsParent: (object) ->
    for own k,v of object
      if Util.stringEndsWith(k,'Binding') and v? and v.length? and v.length>0 and v[0] != v[0].toUpperCase()
        object[k] = "parent."+object[k]
