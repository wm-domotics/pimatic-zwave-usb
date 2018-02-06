module.exports = (env) ->

  Promise = env.require 'bluebird'
  _ = env.require 'lodash'
  commons = require('pimatic-plugin-commons')(env)

  class ZwaveValveController extends env.devices.HeatingThermostat
    constructor: (@config, @plugin, lastState) ->
      @_base = commons.base @, @config.class
      @debug = @plugin.debug || false

      @id = @config.id
      @name = @config.name
      @node = @config.node
      @value_id = null

      @_mode = = lastState?.mode?.value or "--"
      @_setSynced(false)

      @responseHandler = @_createResponseHandler()
      @plugin.protocolHandler.on 'response', @responseHandler

      @_temperatureSetpoint = lastState?.temperatureSetpoint?.value or null
      @_battery = lastState?.battery?.value or "--"
      @_valve = lastState?.valve?.value or null
      @_lastSendTime = 0
      @syncTimeoutTime = @config.syncTimeout * 1000 * 60

      if @syncTimeoutTime > 0
        @timestamp = (new Date()).getTime()
        @setTimestampInterval()

      super()

    timer: ->
      current_time = (new Date()).getTime()
      time_since_last_sync =  current_time - @timestamp
      if time_since_last_sync > @syncTimeoutTime
        @_setSynced(false)

    setTimestampInterval: ->
      cb = @timer.bind @
      setInterval cb, @syncTimeoutTime

    _createResponseHandler: () ->
      return (response) =>
        _node = if @node is response.nodeid then response.nodeid else null
        data = response.zwave_response

        if _node?
          #Update the temperture
          @value_id = data.value_id

          @_base.debug "Response", response

          if data.class_id is 67
            @_base.debug "update temperture", data.value
            @_setSetpoint(parseFloat(data.value))
            #@_setValve(parseInt(data.value) / 28 * 100) #28 == 100%
            @_setSynced(true)
            @timestamp = (new Date()).getTime()

          if data.class_id is 128
            @_base.debug "Update battery", data.value
            battery_value = if parseInt(data.value) < 5 then 'LOW' else 'OK'
            @_setBattery(battery_value)

          if data.class_id is 38
            @_base.debug "Update valve", data.value
            @_setValve(parseInt(data.value))
            @timestamp = (new Date()).getTime()

          if data.class_id is 64
            @_base.debug "Update thermostat mode", data.value
            if data.value is 0
             @_base.debug "thermostat mode is 'Off'"
            else if data.value is 1
             @_base.debug "thermostat mode is 'Heat'"
             @_setMode("auto")
            else if data.value is 11
             @_base.debug "thermostat mode is 'Energy Heat'"
            else if data.value is 15
             @_base.debug "thermostat mode is 'Full Power'"
            else if data.value is 31
             @_base.debug "thermostat mode is 'Manufacturer Specific'"
             @_setMode("manu")
           else
             @_base.debug "No valid thermostat mode received"


    _callbackHandler: () ->
      return (response) =>
        #@TODO: ???
        @_base.debug 'what is this.. when does it happen?? (_callbackHandler in ZwaveThermostat)'

    destroy: () ->
      @_base.cancelUpdate()
      @plugin.protocolHandler.removeListener 'response', @responseHandler
      super()

    changeModeTo(mode) =>
     return new Promise (resolve, reject) =>
        if @_mode is mode then return Promise.resolve()

        if(@value_id)
          if mode is "auto"
           @plugin.protocolHandler.sendRequest({ value_id: @value_id, node_id: @node, class_id: 64, instance:1, index:0}, 1)
           @_setMode(parseFloat(mode));
           @_base.debug "sending request to change mode to auto/Heat/1"
          if mode is "manu"
           @plugin.protocolHandler.sendRequest({ value_id: @value_id, node_id: @node, class_id: 64, instance:1, index:0}, 31)
           @_setMode(parseFloat(mode));
           @_base.debug "sending request to change mode to manu/Manufacturer Specific/31"

        else
          @_base.info "Please wake up ", @name, " device has no value_id yet"

        resolve()

    getMode: -> Promise.resolve(@_mode)

    changeTemperatureTo: (temperatureSetpoint) =>
      return new Promise (resolve, reject) =>
        if @_temperatureSetpoint is temperatureSetpoint then return Promise.resolve()

        if(@value_id)
          if mode is "manu"
            @_base.debug "mode is manu, sending valve percentage request"
            @plugin.protocolHandler.sendRequest({ value_id: @value_id, node_id: @node, class_id: 38, instance:1, index:0}, parseFloat(temperatureSetpoint).toFixed(2), "thermostat")
            @_setValve(parseFloat(temperatureSetpoint));
          else if mode is "auto"
            @_base.debug "mode is auto, sending temperature setpoint request"
            @plugin.protocolHandler.sendRequest({ value_id: @value_id, node_id: @node, class_id: 67, instance:1, index:1}, parseFloat(temperatureSetpoint).toFixed(2), "thermostat")
            @_setSetpoint(parseFloat(temperatureSetpoint));
          else
            @_base.debug "invalid mode"
        else
          @_base.info "Please wake up ", @name, " device has no value_id yet"


        resolve()

    getTemperature: -> Promise.resolve(@_temperatureSetpoint)
