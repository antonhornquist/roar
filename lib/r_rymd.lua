-- TODO: uses engine global (could be passed in init())
-- TODO: assumes R engine is loaded (or should this be done here?)

local R = require('r/lib/r') -- assumes r engine resides in ~/dust/code/r folder
local ControlSpec = require('controlspec') -- TODO
local Formatters = require('formatters')
local CappedList = include('lib/capped_list')

local Module = {}

Module.visual_values = {
  delay_time_left = CappedList.create(util.round(FPS/20)) -- TODO = 2
}

local init_r_params
local init_r_polls

function Module.init()
  init_r()
  local r_polls = init_r_polls()
  local r_params = init_r_params()
  return r_polls, r_params
end

local cutoff_poll -- TODO: to be integrated to lib/rbob
local push_cutoff_visual_value

function init_polls()
  cutoff_poll = poll.set("poll1", function(value)
    push_cutoff_visual_value(value)
    Common.set_ui_dirty()
  end)

  cutoff_poll.time = 1/FPS
end

function Module.start()
  cutoff_poll:start()
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
  engine.set("Filter1.Resonance", 0.1)
  engine.set("Filter2.Resonance", 0.1)
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

local cutoff_spec

function init_params()
  local params = {}

  cutoff_spec = R.specs.LPLadder.Frequency:copy()
  cutoff_spec.default = 1000
  cutoff_spec.minval = 20
  cutoff_spec.maxval = 10000

  table.insert(params, {
    type="control",
    id="cutoff",
    name="Cutoff",
    controlspec=cutoff_spec,
    action=function (value)
      engine.set("FilterL.Frequency", value)
      engine.set("FilterR.Frequency", value)
      Common.set_ui_dirty()
    end
  })

  local resonance_spec = R.specs.LPLadder.Resonance:copy()
  resonance_spec.default = 0.5

  table.insert(params, {
    type="control",
    id="resonance",
    name="Resonance",
    controlspec=resonance_spec,
    formatter=Formatters.percentage,
    action=function (value)
      engine.set("FilterL.Resonance", value)
      engine.set("FilterR.Resonance", value)
      Common.set_ui_dirty()
    end
  })

  local lfo_rate_spec = R.specs.MultiLFO.Frequency:copy()
  lfo_rate_spec.default = 0.5

  table.insert(params, {
    type="control",
    id="lfo_rate",
    name="LFO Rate",
    controlspec=lfo_rate_spec,
    formatter=Formatters.round(0.001),
    action=function (value)
      engine.set("LFO.Frequency", value)
      Common.set_ui_dirty()
    end
  })

  local lfo_to_cutoff_spec = R.specs.LinMixer.In1
  lfo_to_cutoff_spec.default = 0.1

  table.insert(params, {
    type="control",
    id="lfo_to_cutoff",
    name="LFO > Cutoff",
    controlspec=lfo_to_cutoff_spec,
    formatter=Formatters.percentage,
    action=function (value)
      engine.set("ModMix.In1", value)
      Common.set_ui_dirty()
    end
  })

  local env_attack_spec = R.specs.ADSREnv.Attack:copy()
  env_attack_spec.default = 50

  table.insert(params, {
    type="control",
    id="envf_attack",
    name="EnvF Attack",
    controlspec=env_attack_spec, -- TODO
    action=function (value)
      engine.set("EnvF.Attack", value)
      Common.set_ui_dirty()
    end
  })

  local env_decay_spec = R.specs.ADSREnv.Decay:copy()
  env_decay_spec.default = 100

  table.insert(params, {
    type="control",
    id="envf_decay",
    name="EnvF Decay",
    controlspec=env_decay_spec, -- TODO
    action=function (value)
      engine.set("EnvF.Decay", value)
      Common.set_ui_dirty()
    end
  })

  table.insert(params, {
    type="control",
    id="envf_sensitivity",
    name="EnvF Sensitivity",
    controlspec=ControlSpec.new(0, 1), -- TODO
    formatter=Formatters.percentage,
    action=function (value)
      engine.set("EnvF.Sensitivity", value)
      Common.set_ui_dirty()
    end
  })

  local env_to_cutoff_spec = R.specs.LinMixer.In2
  env_to_cutoff_spec.default = 0.1

  table.insert(params, {
    type="control",
    id="env_to_cutoff",
    name="Env > Cutoff",
    controlspec=env_to_cutoff_spec,
    formatter=Formatters.percentage,
    action=function (value)
      engine.set("ModMix.In2", value)
      Common.set_ui_dirty()
    end
  })

  return params
end

function push_cutoff_visual_value(value)
  local visual_value = cutoff_spec:unmap(value)
  CappedList.push(Module.visual_values.cutoff, visual_value)
end

return Module
