module.exports = {
  title: "pimatic-zwave-usb device config schemas"
  ZwaveThermostat: {
    title: "ZWave thermostat options"
    type: "object"
    properties:
      node:
        description: "The zwave nodeid"
        type: "integer"
        default: 0
      guiShowTemperatureInput:
        description: "Show the temperature input spinbox in the gui"
        type: "boolean"
        default: true
      guiShowValvePosition:
        description: "Show the valve position in the gui"
        type: "boolean"
        default: true
      guiShowPresetControl:
        description: "Show the preset temperatures in the GUI"
        type: "boolean"
        default: false
      syncTimeout:
        description: "After this timeout the sync status is reset to false, in minutes"
        type: "integer"
        default: 0
      comfyTemp:
        description: "The defined comfy temperature"
        type: "number"
        default: 21
      ecoTemp:
        description: "The defined eco mode temperature"
        type: "number"
        default: 16
  }
  ZwavePowerSwitch: {
    title: "ZWave powerswitch options"
    type: "object"
    properties:
      node:
        description: "The zwave nodeid"
        type: "integer"
        default: 0
  }
  ZwaveDimmer: {
    title: "ZWave dimmer options"
    type: "object"
    properties:
      node:
        description: "The zwave nodeid"
        type: "integer"
        default: 0
  }
  ZwaveWindowSensor: {
    title: "ZWave window sensor options"
    type: "object"
    properties:
      node:
        description: "The zwave nodeid"
        type: "integer"
        default: 0
      syncTimeout:
        description: "After this timeout the sync status is reset to false, in minutes"
        type: "integer"
        default: 0
  },
  ZwaveTemperatureSensor: {
    title: "ZWave temperature sensor options"
    type: "object"
    properties:
      node:
        description: "The zwave nodeid"
        type: "integer"
        default: 0
      syncTimeout:
        description: "After this timeout the sync status is reset to false, in minutes"
        type: "integer"
        default: 0
  }
}
