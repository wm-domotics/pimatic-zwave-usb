
module.exports = (env) ->
  Promise = env.require 'bluebird'
  _ = env.require 'lodash'
  commons = require('pimatic-plugin-commons')(env)

  class ZwaveTemperatureSensor extends env.devices.TemperatureSensor

    constructor: (@config, @plugin, lastState) ->
      @_base = commons.base @, @config.class
      @debug = @plugin.debug || false

      @id = @config.id
      @name = @config.name
      @node = @config.node
      @value_id = null
      @_setSynced(false)
      @responseHandler = @_createResponseHandler()
      @plugin.protocolHandler.on 'response', @responseHandler
      @_temperature = lastState?.temperature?.value or null
      @_battery = lastState?.battery?.value or "--"

      @syncTimeoutTime = @config.syncTimeout * 1000 * 60

      if @syncTimeoutTime > 0
        @timestamp = (new Date()).getTime()
        @setTimestampInterval()

      super()

    attributes:
      synced:
        description: "Pimatic and sensor in sync"
        type: "boolean"
      battery:
        description: "Battery status"
        type: "string"
        enum: ["ok", "low"]
      temperature:
        label: "Temperature"
        description: "The measured temperature"
        type: "number"
        discrete: true
        unit: "°C"

    getTemperature: () -> Promise.resolve(@_temperature)
    getBattery: () -> Promise.resolve(@_battery)
    getSynced: () -> Promise.resolve(@_synced)

    timer: ->
      current_time = (new Date()).getTime()
      time_since_last_sync =  current_time - @timestamp
      if time_since_last_sync > @syncTimeoutTime
        @_setSynced(false)

    setTimestampInterval: ->
      cb = @timer.bind @
      setInterval cb, @syncTimeoutTime

    _setSynced: (synced) ->
      if synced is @_synced then return
      @_synced = synced
      @emit "synced", @_synced

    _setTemperature: (temperature) ->
      if temperature is @_temperature then return
      @_temperature = temperature
      @emit "temperature", @_temperature

    _setBattery: (battery) ->
      if battery is @_battery then return
      @_battery = battery
      @emit "battery", @_battery

    destroy: () ->
      @_base.cancelUpdate()
      @plugin.protocolHandler.removeListener 'response', @responseHandler
      super()

    _createResponseHandler: () =>
      return (response) =>
        _node = if @node is response.nodeid then response.nodeid else null
        data = response.zwave_response

        if _node? && data.class_id

          @value_id = data.value_id
          if data.class_id is 49 && data.index is 1
            @_base.debug "update temperture", data.value
            temp = parseFloat(data.value);
            temp = Math.round(temp * 10) / 10;

            @timestamp = (new Date()).getTime()
            @_setTemperature(temp)
            @_setSynced(true)

          if(data.class_id is 128)
            @_base.debug "Update battery", data.value
            battery_value = if parseInt(data.value) < 5 then 'LOW' else 'OK'
            @_setBattery(battery_value)
          #@_setState data.value
