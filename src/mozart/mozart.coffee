Mozart =
  version: "0.1.8"
  versionDate: new Date 2013, 6, 1
  Plugins: {}

Mozart[name] = method for own name, method of module for module in [
  require "./collection"
  require "./control"
  require "./controller"
  require "./data-index"
  require "./dom-manager"
  require "./events"
  require "./handlebars"
  require "./http"
  require "./layout"
  require "./model-instance"
  require "./model-instancecollection"
  require "./model-onetomanycollection"
  require "./model-onetomanypolycollection"
  require "./model-manytomanycollection"
  require "./model-manytomanypolycollection"
  require "./model-manytomanypolyreversecollection"
  require "./model-ajax"
  require "./model-localstorage"
  require "./model"
  require "./object"
  require "./route"
  require "./router"
  require "./switch-view"
  require "./util"
  require "./view"
  require "./dynamic-view"
  require "./cookies"
]

if global.module?
  module.exports = Mozart
else if global.define?.amd?
  define "mozart", Mozart
else
  global.Mozart = Mozart
