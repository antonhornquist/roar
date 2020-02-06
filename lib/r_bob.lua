-- TODO: uses engine global (could be passed in init())
-- TODO: assumes R engine is loaded (or should this be done here?)

local R = require('r/lib/r') -- assumes r engine resides in ~/dust/code/r folder
local ControlSpec = require('controlspec')
local Formatters = require('formatters')
local CappedList = include('lib/capped_list')

local Module = {}

Module.visual_values = {
  cutoff = CappedList.create(util.round(FPS/20)) -- TODO = 2
}

local init_r
local init_params
local init_polls

function Module.init()
  init_r()
  local bob_params = init_params()
  local bob_polls = init_polls()
  return bob_params, bob_polls
end

local cutoff_spec
local cutoff_poll -- TODO: to be integrated to lib/rbob

function init_polls()
  return {
    {
      id = "cutoff",
      handler = function(value)
        local visual_value = cutoff_spec:unmap(value)
        CappedList.push(Module.visual_values.cutoff, visual_value)
      end
    }
  }
end

local create_modules
local set_static_module_params
local connect_modules

function init_r()
  create_modules()
  set_static_module_params()
  connect_modules()

  engine.pollvisual(0, "FilterL.Frequency") -- TODO: should be indexed from 1
end

function create_modules()
  engine.new("LFO", "MultiLFO")
  engine.new("SoundIn", "SoundIn")
  engine.new("EnvF", "EnvF")
  engine.new("ModMix", "LinMixer")
  engine.new("FilterL", "LPLadder")
  engine.new("FilterR", "LPLadder")
  engine.new("SoundOut", "SoundOut")
end

function set_static_module_params()
  engine.set("FilterL.FM", 1)
  engine.set("FilterR.FM", 1)
  engine.set("ModMix.Out", 1)
end

function connect_modules()
  engine.connect("SoundIn/Left", "FilterL/In")
  engine.connect("SoundIn/Right", "FilterR/In")
  engine.connect("LFO/Sine", "ModMix/In1")
  engine.connect("SoundIn/Left", "EnvF/In")
  engine.connect("EnvF/Env", "ModMix/In2")
  engine.connect("ModMix/Out", "FilterL/FM")
  engine.connect("ModMix/Out", "FilterR/FM")
  engine.connect("FilterL/Out", "SoundOut/Left")
  engine.connect("FilterR/Out", "SoundOut/Right")
end

function init_params()
  local bob_params = {}

  cutoff_spec = R.specs.LPLadder.Frequency:copy()
  cutoff_spec.default = 1000
  cutoff_spec.minval = 20
  cutoff_spec.maxval = 10000

  table.insert(bob_params, {
    id="cutoff",
    name="Cutoff",
    controlspec=cutoff_spec,
    action=function (value)
      engine.set("FilterL.Frequency", value)
      engine.set("FilterR.Frequency", value)
      -- TODO Common.set_ui_dirty()
    end
  })

  local resonance_spec = R.specs.LPLadder.Resonance:copy()
  resonance_spec.default = 0.5

  table.insert(bob_params, {
    id="resonance",
    name="Resonance",
    controlspec=resonance_spec,
    formatter=Formatters.percentage,
    action=function (value)
      engine.set("FilterL.Resonance", value)
      engine.set("FilterR.Resonance", value)
      -- TODO Common.set_ui_dirty()
    end
  })

  local lfo_rate_spec = R.specs.MultiLFO.Frequency:copy()
  lfo_rate_spec.default = 0.5

  table.insert(bob_params, {
    id="lfo_rate",
    name="LFO Rate",
    controlspec=lfo_rate_spec,
    formatter=Formatters.round(0.001),
    action=function (value)
      engine.set("LFO.Frequency", value)
      -- TODO Common.set_ui_dirty()
    end
  })

  local lfo_to_cutoff_spec = R.specs.LinMixer.In1
  lfo_to_cutoff_spec.default = 0.1

  table.insert(bob_params, {
    id="lfo_to_cutoff",
    name="LFO > Cutoff",
    controlspec=lfo_to_cutoff_spec,
    formatter=Formatters.percentage,
    action=function (value)
      engine.set("ModMix.In1", value)
      -- TODO Common.set_ui_dirty()
    end
  })

  local env_attack_spec = R.specs.ADSREnv.Attack:copy()
  env_attack_spec.default = 50

  table.insert(bob_params, {
    id="envf_attack",
    name="EnvF Attack",
    controlspec=env_attack_spec, -- TODO
    action=function (value)
      engine.set("EnvF.Attack", value)
      -- TODO Common.set_ui_dirty()
    end
  })

  local env_decay_spec = R.specs.ADSREnv.Decay:copy()
  env_decay_spec.default = 100

  table.insert(bob_params, {
    id="envf_decay",
    name="EnvF Decay",
    controlspec=env_decay_spec, -- TODO
    action=function (value)
      engine.set("EnvF.Decay", value)
      -- TODO Common.set_ui_dirty()
    end
  })

  table.insert(bob_params, {
    id="envf_sensitivity",
    name="EnvF Sensitivity",
    controlspec=ControlSpec.new(0, 1), -- TODO
    formatter=Formatters.percentage,
    action=function (value)
      engine.set("EnvF.Sensitivity", value)
      -- TODO Common.set_ui_dirty()
    end
  })

  local env_to_cutoff_spec = R.specs.LinMixer.In2
  env_to_cutoff_spec.default = 0.1

  table.insert(bob_params, {
    id="env_to_cutoff",
    name="Env > Cutoff",
    controlspec=env_to_cutoff_spec,
    formatter=Formatters.percentage,
    action=function (value)
      engine.set("ModMix.In2", value)
      -- TODO Common.set_ui_dirty()
    end
  })

  for _,bob_param in ipairs(bob_params) do
    bob_param.type = "control"
  end

  return bob_params
end

return Module
