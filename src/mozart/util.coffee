_logging = {}
_idCounter = 0

Util = module.exports =
  toString: Object.prototype.toString

  getType: (object) ->
    @toString.call(object).match(/^\[object\s(.*)\]$/)[1]

  isObject: (object) ->
    @getType(object) is 'Object'

  isFunction: (object) ->
    @getType(object) is 'Function'

  isArray: (object) ->
    @getType(object) is 'Array'

  isString: (object) ->
    @getType(object) is 'String'

  isBoolean: (object) ->
    @getType(object) is 'Boolean'

  log: (type, attrs...) ->
    console.log type + ":", attrs... if _logging[type]? and console?

  showLog: (type) ->
    _logging[type] = true

  hideLog: (type) ->
    _logging[type] = false

  error: (message, attrs...) ->
    console.error("Exception:", message, attrs) if console?
    throw message

  warn: (message, attrs...) ->
    console.log("Warning:", message, attrs) if console?

  clone: (obj) ->
    $.extend({}, obj)

  getPath: (context, path) ->
    value = @_getPath(context, path)
    throw new Error "Object #{context} has no #{path}" if value is undefined
    value

  isAbsolutePath: (path) ->
    path[0].toUpperCase() == path[0]

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

  getId: ->
    ++_idCounter

  parsePath: (path) ->
    if path.indexOf('.') == -1
      return [ null, path ]
    props = path.split('.')
    lastprop = props.pop()
    [ props.join('.'), lastprop ]

  toMap: (itemArray, idfield = 'id') ->
    map = {}
    for item in itemArray
      map[item[idfield]] = item
    map

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

  toCapsCase: (name) =>
    x = name.replace /^[a-z]{1,1}/g, (match) -> match.toUpperCase()
    x = x.replace /_[a-z]{1,1}/g, (match) -> match.toUpperCase()
    x = x.replace /_/g, " "
    x

  toSnakeCase: (name) =>
    x = name.replace /[A-Z]{1,1}/g, (match) =>
      "_" + match.toLowerCase()
    x.replace /^_/, ""

  sliceStringBefore: (str, token) ->
    str.slice(0, str.length - token.length)

  sliceStringAfter: (str, token) ->
    str.slice(token.length)

  stringEndsWith: (str, token) ->
    len = token.length
    (str.length >= len) && (str.slice(-len) == token)

  stringStartsWith: (str, token) ->
    len = token.length
    (str.length >= len) && (str.slice(0, len) == token)

  addBindingsParent: (object) ->
    for own k,v of object
      if Util.stringEndsWith(k,'Binding') and v? and v.length? and v.length>0 and v[0] != v[0].toUpperCase()
        object[k] = "parent."+object[k]
