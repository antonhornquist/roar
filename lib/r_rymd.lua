-- TODO: uses engine global (could be passed in init())
-- TODO: assumes R engine is loaded (or should this be done here?)

local R = require('r/lib/r') -- assumes r engine resides in ~/dust/code/r folder
local ControlSpec = require('controlspec') -- TODO
local Formatters = require('formatters')
local CappedList = include('lib/capped_list')

local Module = {}

local init_r
local init_visual_values_bufs
local init_r_params
local init_r_polls

function Module.init(visual_buf_size)
  init_r()
  init_visual_values_bufs(visual_buf_size)
  local r_polls = init_r_polls()
  local r_params = init_r_params()
  return r_polls, r_params
end

local create_modules
local set_static_module_params
local connect_modules

function init_r()
  create_modules()
  set_static_module_params()
  connect_modules()
  engine.pollvisual(0, "Delay1.DelayTime") -- TODO: should be indexed from 1
  engine.pollvisual(1, "Delay2.DelayTime") -- TODO: should be indexed from 1
end

function create_modules()
  engine.new("LFO", "MultiLFO")
  engine.new("SoundIn", "SoundIn")
  engine.new("Direct", "SGain")
  engine.new("FXSend", "SGain")
  engine.new("Delay1", "Delay")
  engine.new("Delay2", "Delay")
  engine.new("Filter1", "MMFilter")
  engine.new("Filter2", "MMFilter")
  engine.new("Feedback", "SGain")
  engine.new("SoundOut", "SoundOut")
end

function set_static_module_params()
  engine.set("Filter1.Resonance", 0) -- TODO: or is this the default? then no need to set
  engine.set("Filter2.Resonance", 0) -- TODO: or is this the default? then no need to set
end

function connect_modules()
  engine.connect("LFO/Sine", "Delay1/DelayTimeModulation")
  engine.connect("LFO/Sine", "Delay2/DelayTimeModulation")
  engine.connect("SoundIn/Left", "Direct/Left")
  engine.connect("SoundIn/Right", "Direct/Right")
  engine.connect("Direct/Left", "SoundOut/Left")
  engine.connect("Direct/Right", "SoundOut/Right")

  engine.connect("SoundIn/Left", "FXSend/Left")
  engine.connect("SoundIn/Right", "FXSend/Right")
  engine.connect("FXSend/Left", "Delay1/In")
  engine.connect("FXSend/Right", "Delay2/In")
  engine.connect("Delay1/Out", "Filter1/In")
  engine.connect("Delay2/Out", "Filter2/In")
  engine.connect("Filter1/Lowpass", "Feedback/Left")
  engine.connect("Filter2/Lowpass", "Feedback/Right")
  engine.connect("Feedback/Left", "Delay2/In")
  engine.connect("Feedback/Right", "Delay1/In")
  engine.connect("Filter1/Lowpass", "SoundOut/Left")
  engine.connect("Filter2/Lowpass", "SoundOut/Right")
end

function init_visual_values_bufs(visual_buf_size)
  Module.visual_values = {
    delay_time_left = CappedList.create(visual_buf_size),
    delay_time_right = CappedList.create(visual_buf_size)
  }
end

local delay_time_left_spec
local delay_time_right_spec

function init_r_polls()
  return {
    {
      id = "delay_time_left",
      handler = function(value)
        local visual_value = delay_time_left_spec:unmap(value) -- TODO: this should use an edited version of the Visual spec
        CappedList.push(Module.visual_values.delay_time_left, visual_value)
      end
    },
    {
      id = "delay_time_right",
      handler = function(value)
        local visual_value = delay_time_right_spec:unmap(value) -- TODO: this should use an edited version of the Visual spec
        CappedList.push(Module.visual_values.delay_time_right, visual_value)
      end
    }
  }
end

function init_r_params()
  local r_params = {}

  table.insert(r_params, {
    id="direct",
    name="Direct",
    controlspec=R.specs.SGain.Gain,
    action=function (value)
      engine.set("Direct.Gain", value)
    end
  })

  local delay_send_spec = R.specs.SGain.Gain
  delay_send_spec.default = -10

  table.insert(r_params, {
    id="delay_send",
    name="Delay Send",
    controlspec=delay_send_spec,
    action=function (value)
      engine.set("FXSend.Gain", value)
    end
  })

  delay_time_left_spec = R.specs.Delay.DelayTime
  delay_time_left_spec.default = 400

  table.insert(r_params, {
    id="delay_time_left",
    name="Delay Time Left",
    controlspec=delay_time_left_spec,
    action=function (value)
      engine.set("Delay1.DelayTime", value)
    end
  })

  delay_time_right_spec = R.specs.Delay.DelayTime
  delay_time_right_spec.default = 300

  table.insert(r_params, {
    id="delay_time_right",
    name="Delay Time Right",
    controlspec=delay_time_right_spec,
    action=function (value)
      engine.set("Delay2.DelayTime", value)
    end
  })

  local filter_spec = R.specs.MMFilter.Frequency:copy()
  filter_spec.default = 4000
  filter_spec.maxval = 10000

  table.insert(r_params, {
    id="damping",
    name="Damping",
    controlspec=filter_spec,
    action=function(value)
      engine.set("Filter1.Frequency", value)
      engine.set("Filter2.Frequency", value)
    end
  })

  local feedback_spec = R.specs.SGain.Gain:copy()
  feedback_spec.default = -10
  feedback_spec.maxval = 0

  table.insert(r_params, {
    id="feedback",
    name="Feedback",
    controlspec=feedback_spec,
    action=function (value)
      engine.set("Feedback.Gain", value)
    end
  })

  table.insert(r_params, {
    id="mod_rate",
    name="Mod Rate",
    controlspec=R.specs.MultiLFO.Frequency,
    formatter=Formatters.round(0.001),
    action=function (value)
      engine.set("LFO.Frequency", value)
    end
  })

  table.insert(r_params, {
    id="delay_time_mod_depth",
    name="Delay Time Mod Depth",
    controlspec=ControlSpec.UNIPOLAR,
    formatter=Formatters.percentage,
    action=function(value)
      engine.set("Delay1.DelayTimeModulation", value)
      engine.set("Delay2.DelayTimeModulation", value)
    end
  })

  for _,r_param in ipairs(r_params) do
    r_param.type = "control"
  end

  return r_params
end

return Module
