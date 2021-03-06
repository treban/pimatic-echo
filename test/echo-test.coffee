assert = require "assert"
grunt = require "grunt"
Promise = require 'bluebird'

env = require("../node_modules/pimatic/startup").env

describe "echo", ->

  plugin = require("../echo")(env)

  describe "_isSupported", ->

    it "should return true if device has a known template", ->
      assert plugin._isSupported({ template: template }) for template in plugin.switchTemplates
      assert plugin._isSupported({ template: template }) for template in plugin.dimmerTemplates

    it "should return false if template is unknown", ->
      assert plugin._isSupported({ template: "foo"}) is false

  describe "_isExcluded", ->

    it "should return true if no echo config exists", ->
      device = {
        template: "switch"
        config : {}
      }
      assert plugin._isExcluded(device) is true
      assert device.config.hasOwnProperty('echo')
      assert device.config.echo.hasOwnProperty('active')
      assert device.config.echo.active is false

    it "should migrate exclude flag", ->
      device = {
        template: 'switch'
        config:
          echo:
            exclude: false
      }
      assert plugin._isExcluded(device) is false
      assert !device.config.echo.hasOwnProperty('exclude')
      assert device.config.echo.hasOwnProperty('active')
      assert device.config.echo.active is true

    it "should return true if device is not active", ->
      assert plugin._isExcluded({
        config:
          echo:
            active: false
      }) is true

    it "should return false if device is active", ->
      assert plugin._isExcluded({
        template: 'switch'
        config:
          echo:
            active: true
      }) is false

  describe "_getDeviceName", ->

    it "should return device name if no config exists", ->
      expected = "devicename"
      assert plugin._getDeviceName({
        name: expected
        config:
          echo: {}
      }) is expected

    it "should return name from config", ->
      expected = "devicename"
      assert plugin._getDeviceName({
        name: "othername"
        config:
          echo:
            name: expected
      }) is expected

  describe "_getAdditionalNames", ->

    it "should return empty list no config exists", ->
      assert plugin._getAdditionalNames({
        name: "device"
        config:
          echo: {}
      }).length is 0

    it "should return names from config", ->
      additionalNames = plugin._getAdditionalNames({
        name: "othername"
        config:
          echo:
            additionalNames: ["1", "2"]
      })
      assert additionalNames[0] is "1"
      assert additionalNames[1] is "2"

  describe "turnOn", ->

    it "should call moveUp for shutter device", ->
      wasCalled = false
      device = {
        template: "shutter"
        moveUp: () =>
          wasCalled = true
          return Promise.resolve()
      }
      plugin._turnOn(device)
      assert wasCalled

    it "should call buttonPressed for ButtonsDevice", ->
      wasCalled = false
      device = {
        template: "buttons"
        config: 
          buttons: [
            id: 1
          ]
        buttonPressed: (id) =>
          assert id is 1
          wasCalled = true
          return Promise.resolve()
      }
      plugin._turnOn(device)
      assert wasCalled

    it "should call turnOn for switches", ->
      wasCalled = false
      device = {
        template: "switch"
        turnOn: () =>
          wasCalled = true
          return Promise.resolve()
      }
      plugin._turnOn(device)
      assert wasCalled

  describe "turnOff", ->

    it "should call moveDown for shutter device", ->
      wasCalled = false
      device = {
        template: "shutter"
        moveDown: () =>
          wasCalled = true
          return Promise.resolve()
      }
      plugin._turnOff(device)
      assert wasCalled

    it "should not call buttonPressed for ButtonsDevice", ->
      wasCalled = false
      device = {
        template: "buttons"
        config: 
          buttons: [
            id: 1
          ]
        buttonPressed: (id) =>
          assert false
          wasCalled = true
          return Promise.resolve()
      }
      plugin._turnOff(device)
      assert wasCalled is false

    it "should call turnOff for switches", ->
      wasCalled = false
      device = {
        template: "switch"
        turnOff: () =>
          wasCalled = true
          return Promise.resolve()
      }
      plugin._turnOff(device)
      assert wasCalled
