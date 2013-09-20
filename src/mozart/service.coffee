{MztObject} = require './object'

# Service is the base class for Mozart Services.
# 
# Services are generally useful for working with endpoints that don't have a 1-to-1 mapping 
# with individual models, and where complex loading and saving logic exists, by encapsulating 
# the required AJAX/WebSocket code.
class Service extends MztObject

exports.Service = Service
