Util = require './util'
{View} = require './view'
{I18nView} = require './i18n-view'
{Collection} = require './collection'

getPath = (context, path) ->
  Util._getPath(context, path)

_value = (context, path) ->
  if typeof path == 'string'
    value = Util._getPath(context, path)
  else if typeof path == 'function'
    value = path.call(context)
  value

Handlebars.registerHelper "site", (context, options) ->
  new Handlebars.SafeString("/#")

Handlebars.registerHelper "bind", (context, options) ->
  Util.log('handlebars',"handlebars helper 'bind':", @, context,options)
  
  Util.error("Bind helper must have a target.") if arguments.length == 1

  bindId = "bind#{ Util.getId() }"

  tag = options.hash.tag ? 'span'

  buffer = "<#{tag} id='#{bindId}'"
  for k,v of options.hash when Util.stringEndsWith(k, 'Html')
    buffer +=' ' + Util.sliceStringBefore(k, 'Html') + '="'+v+'"'
  buffer += "></#{tag}>"
  
  options.data.registerDomBind(bindId,context)

  new Handlebars.SafeString(buffer)

Handlebars.registerHelper "i18n", (context, options) ->
  Util.log('handlebars',"handlebars helper 'i18n':", @, context, options)
  if arguments.length == 1
    buffer = ""
    Util.error("i18n helper usage must reference a key.")
  else
    fn = Util._getPath(window,"i18n.#{context}")
    unless fn?
      Util.error("i18n helper: key '#{context}' does not exist in current language file.")
      buffer = ""
    else
      mzthash = if options? and options.hash? then Mozart.MztObject.create(options.hash) else {}
      buffer = Util.getPath(window, "i18n.#{context}")(mzthash)

  new Handlebars.SafeString(buffer)

Handlebars.registerHelper "bindI18n", (context, options) ->
  Util.log('handlebars',"handlebars helper 'bindI18n':", @, context,options)
  
  Util.error("bindI18n helper must have a target.") if arguments.length == 1

  vco =
    context: @
    i18nTemplate: context
    parent: options.data

  if options.hash?
    Util.addBindingsParent(options.hash)
    for k,v of options.hash
      vco[k] = v

  view = vco.parent.layout.createView(I18nView,vco)
  vco.parent.addView(view)

  preElement = view.createElement()
  content = preElement.outerHTML
  content ?= ""
  vco.parent.layout.queueRenderView(view)
  new Handlebars.SafeString(content)


Handlebars.registerHelper "view", (context, options) ->
  Util.log('handlebars',"handlebars helper 'view':", @, context,options)

  if arguments.length == 1
    options = context
    context = null

  parentView = options.data

  if context?
    if typeof(context) == "string"
      viewClass = Util._getPath(context)
    else
      viewClass = context
  else
    viewClass = View
  
  Util.error("view handlebars helper: viewClass does not exist", "context",context, "this",@) unless viewClass?

  viewCreateOptions =
    context: @
    parent: parentView

  if options.fn?
    viewCreateOptions.templateFunction = options.fn
  if options.hash?
    Util.addBindingsParent(options.hash)
    for k,v of options.hash
      viewCreateOptions[k] = v

  view = parentView.layout.createView(viewClass,viewCreateOptions)
  parentView.addView(view)

  preElement = view.createElement()
  content = preElement.outerHTML
  content ?= ""
  parentView.layout.queueRenderView(view)
  new Handlebars.SafeString(content)

Handlebars.registerHelper "collection", (context, options) ->
  Util.log('handlebars',"handlebars helper 'collection':", @, Util.clone(context), options)

  if arguments.length == 1
    options = context
    context = null
    viewClass = View
  else
    viewClass = Util.getPath(context)
    unless viewClass?
      Util.error "View for collection does not exist", "view name",context

  parentView = options.data
  
  viewOpts =     
    context: @
    viewClass: viewClass
    parent: parentView
  
  viewOpts.viewClassTemplateFunction = options.fn if options.fn?

  Util.addBindingsParent(options.hash)
  
  for k,v of options.hash
    viewOpts[k] = v

  if options.hash.collectionClass?
    collectionClass = Util.getPath(options.hash.collectionClass)
  else
    collectionClass = Collection

  view = parentView.layout.createView(collectionClass, viewOpts)
  view.parent = parentView
  parentView.addView(view)

  preElement = view.createElement()
  content = preElement.outerHTML
  content ?= ""
  parentView.layout.queueRenderView(view)
  new Handlebars.SafeString(content)
  
Handlebars.registerHelper "linkTo", (record, options) ->
  Util.log('handlebars',"handlebars helper 'linkTo':", @, record, options)
  
  options = record if arguments.length==1

  if typeof record == 'string'
    record = Util._getPath(@, record)
  else if typeof record == 'function'
    record = record.call(@)
  
  if record?
    ret = "<a href='/#"+record.showUrl()+"'"
    if options.hash?.classNames?
      ret +=" class='"+options.hash.classNames+"'"
    ret += ">"
    text = options.fn @
    unless text? and text.length > 0
      text = "(Empty Value)"
    ret += text
    ret += '</a>'
    new Handlebars.SafeString(ret)
  else
    ""

Handlebars.registerHelper "valueOf", (record, options) ->
  Util.log('handlebars',"handlebars helper 'valueOf':", @, record, options)
  
  options = record if arguments.length==1

  value = Util._getPath(@, record)
  value = "" unless value?

  new Handlebars.SafeString(value)

Handlebars.registerHelper "rawPath", (record, options) ->
  
  options = record if arguments.length==1

  value = Util._getPath(@, record)
  value = "" unless value?
  value

Handlebars.registerHelper "uriPath", (record, options) ->
  
  options = record if arguments.length==1

  value = Util._getPath(@, record)
  value = "" unless value?
  value
  encodeURI(value)

Handlebars.registerHelper "valueEach", (record, options) ->
  Util.log('handlebars',"handlebars helper 'valueEach':", @, record, options)
  if arguments.length==1
    options = record

  record = Util.getPath(@, record)

  return "" unless record?

  out = ""
  for context in record
    out += options.fn context
    out += options.hash.seperator if options?.hash?.seperator?
  
  out = out.slice(0,out.length - options.hash.seperator.length) if options?.hash?.seperator? and out.length>0

  new Handlebars.SafeString(out)

Handlebars.registerHelper "yesNo", (path, options) ->
  Util.log('handlebars',"handlebars helper 'yesNo':", @, path, options)
  
  options = path if arguments.length==1
  
  path = Util.getPath(@, path) if typeof path == 'string'

  return "No" unless path?

  if path then "Yes" else "No"

Handlebars.registerHelper "valueIf", (context, options) ->
  Util.log('handlebars',"handlebars helper 'valueOf':", @, context, options)
  if typeof context == 'string'
    context = Util._getPath(@, context)

  if context
    options.fn @
  else
    options.inverse @

Handlebars.registerHelper "valueUnless", (context, options) ->
  if typeof context == 'string'
    context = Util.getPath(@, context)

  if not context
    options.fn @
  else
    options.inverse @

Handlebars.registerHelper "action", (action, options) ->
  Util.log('handlebars',"handlebars helper 'action':", @, action, options)
    
  # Find method to call
  [path, action] = Util.parsePath(action)

  # No path = context is current view
  if path?
    target = Util.getPath(options.data, path)
  else
    target = options.data

  # Setup data attr and actionId
  actionId = Util.getId()
  ret = 'data-mozart-action="'+actionId+'"'

  # Process Allowed Events
  if options.hash.events?
    evt = options.hash.events.split(',')
  else
    evt = ["click"]

  # Add control
  options.data.layout.addControl actionId,
    action: action
    view: target
    options: options.hash
    events: evt
    allowDefault: (options.hash.allowDefault == true)

  new Handlebars.SafeString(ret)

#Formatting helpers
Handlebars.registerHelper "date", (path) ->
  value = _value(@, path)
  formatted = Util.serverToLocalDate(value) || '(none)'
  new Handlebars.SafeString(formatted)

Handlebars.registerHelper "dateTime", (path) ->
  value = _value(@, path)
  formatted = Util.serverToLocalDateTime(value)
  new Handlebars.SafeString(formatted)

Handlebars.registerHelper "timeAgo", (path) ->
  value = _value(@, path)
  formatted = Util.serverToLocalTimeAgo(value)
  new Handlebars.SafeString(formatted)

Handlebars.registerHelper "mozartversion", ->
  new Handlebars.SafeString(Mozart.version)

Handlebars.registerHelper "mozartversiondate", ->
  new Handlebars.SafeString(Mozart.versionDate.toLocaleDateString())
