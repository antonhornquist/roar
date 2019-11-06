-- scriptname: bob
-- v1.2.0 @jah

engine.name = 'R'

SETTINGS_FILE = "bob.data"

R = require('r/lib/r') -- assumes r engine resides in ~/dust/code/r folder
ControlSpec = require('controlspec')
Formatters = require('formatters')
UI = include('lib/ui')
RoarFormatters = include('lib/formatters')
include('lib/common_ui') -- defines redraw, enc, key and other global functions

local filter_spec
local resonance_spec

function init()
  create_modules()
  set_static_module_params()
  connect_modules()

  init_params()
  init_ui()

  load_settings()
  load_params()

  engine.pollvisual(0, "FilterL.Frequency") -- TODO: should be indexed from 1

  enc2_values = {}
  local poll = poll.set("poll1", function(value)
    if ui_get_current_page_param_id(1) == "cutoff" then
      show_enc2_value = true
      --[[
      enc2_value = filter_spec:unmap(value)
      ]]
      if #enc2_values > 5 then
        table.remove(enc2_values, 1)
      end
      --table.remove(enc2_values, 1)
      table.insert(enc2_values, filter_spec:unmap(value))
      enc2_ref = filter_spec:unmap(params:get("cutoff"))

      show_enc3_value = true
      enc3_ref = resonance_spec:unmap(params:get("resonance"))
    else
      show_enc2_value = false
      show_enc3_value = false
    end
    UI.set_dirty()
  end)
  poll:start()

  ui_run_ui()
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
  filter_spec = R.specs.LPLadder.Frequency:copy()
  filter_spec.default = 1000
  filter_spec.minval = 20
  filter_spec.maxval = 10000

  params:add {
    type="control",
    id="cutoff",
    name="Cutoff",
    controlspec=filter_spec,
    action=function (value)
      engine.set("FilterL.Frequency", value)
      engine.set("FilterR.Frequency", value)
      UI.set_dirty()
    end
  }

  resonance_spec = R.specs.LPLadder.Resonance:copy()
  resonance_spec.default = 0.5

  params:add {
    type="control",
    id="resonance",
    name="Resonance",
    controlspec=resonance_spec,
    formatter=Formatters.percentage,
    action=function (value)
      engine.set("FilterL.Resonance", value)
      engine.set("FilterR.Resonance", value)
      UI.set_dirty()
    end
  }

  local lfo_rate_spec = R.specs.MultiLFO.Frequency:copy()
  lfo_rate_spec.default = 0.5

  params:add {
    type="control",
    id="lfo_rate",
    name="LFO Rate",
    controlspec=lfo_rate_spec,
    formatter=Formatters.round(0.001),
    action=function (value)
      engine.set("LFO.Frequency", value)
      UI.set_dirty()
    end
  }

  local lfo_to_cutoff_spec = R.specs.LinMixer.In1
  lfo_to_cutoff_spec.default = 0.1

  params:add {
    type="control",
    id="lfo_to_cutoff",
    name="LFO > Cutoff",
    controlspec=lfo_to_cutoff_spec,
    formatter=Formatters.percentage,
    action=function (value)
      engine.set("ModMix.In1", value)
      UI.set_dirty()
    end
  }

  local env_attack_spec = R.specs.ADSREnv.Attack:copy()
  env_attack_spec.default = 50

  params:add {
    type="control",
    id="envf_attack",
    name="EnvF Attack",
    controlspec=env_attack_spec, -- TODO
    action=function (value)
      engine.set("EnvF.Attack", value)
      UI.set_dirty()
    end
  }

  local env_decay_spec = R.specs.ADSREnv.Decay:copy()
  env_decay_spec.default = 100

  params:add {
    type="control",
    id="envf_decay",
    name="EnvF Decay",
    controlspec=env_decay_spec, -- TODO
    action=function (value)
      engine.set("EnvF.Decay", value)
      UI.set_dirty()
    end
  }

  params:add {
    type="control",
    id="envf_sensitivity",
    name="EnvF Sensitivity",
    controlspec=ControlSpec.new(0, 1), -- TODO
    formatter=Formatters.percentage,
    action=function (value)
      engine.set("EnvF.Sensitivity", value)
      UI.set_dirty()
    end
  }

  local env_to_cutoff_spec = R.specs.LinMixer.In2
  env_to_cutoff_spec.default = 0.1

  params:add {
    type="control",
    id="env_to_cutoff",
    name="Env > Cutoff",
    controlspec=env_to_cutoff_spec,
    formatter=Formatters.percentage,
    action=function (value)
      engine.set("ModMix.In2", value)
      UI.set_dirty()
    end
  }
end

function init_ui()
  UI.init_arc {
    device = arc.connect(),
    on_delta = function(n, delta)
      ui_arc_delta(n, delta)
    end,
    on_refresh = function(my_arc)
      my_arc:all(0)
      my_arc:led(1, util.round(params:get_raw(ui_get_current_page_param_id(1))*64), 15)
      my_arc:led(2, util.round(params:get_raw(ui_get_current_page_param_id(2))*64), 15)
    end
  }

  UI.init_screen {
    on_refresh = function()
      redraw()
    end
  }

  page_params = {
    {
      {
        label="FREQ",
        id="cutoff",
        value=function(id)
          return RoarFormatters.adaptive_freq(params:get(id))
        end
      },
      {
        label="RES",
        id="resonance",
        value=function(id)
          return RoarFormatters.percentage(params:get(id))
        end
      }
    },
    {
      {
        label="LFO",
        id="lfo_rate",
        value=function(id)
          return RoarFormatters.adaptive_freq(params:get(id))
        end
      },
      {
        label="L>FRQ",
        id="lfo_to_cutoff",
        value=function(id)
          return RoarFormatters.percentage(params:get(id))
        end
      }
    },
    {
      {
        label="E.ATK",
        id="envf_attack",
        value=function(id)
          return RoarFormatters.adaptive_time(params:get(id))
        end
      },
      {
        label="E.DEC",
        id="envf_decay",
        value=function(id)
          return RoarFormatters.adaptive_time(params:get(id))
        end
      },
    },
    {
      {
        label="E.SNS",
        id="envf_sensitivity",
        value=function(id)
          return RoarFormatters.percentage(params:get(id))
        end
      },
      {
        label="E>FRQ",
        id="env_to_cutoff",
        value=function(id)
          return RoarFormatters.percentage(params:get(id))
        end
      }
    }
  }
end

function load_settings()
  local fd=io.open(norns.state.data .. SETTINGS_FILE,"r")
  if fd then
    io.input(fd)
    ui_set_page(tonumber(io.read()))
    io.close(fd)
  else
    ui_set_page(1)
  end
end

function load_params()
  params:read()
  params:bang()
end

function cleanup()
  save_settings()
  params:write()
end

function save_settings()
  local fd=io.open(norns.state.data .. SETTINGS_FILE,"w+")
  io.output(fd)
  io.write(ui_get_page() .. "\n")
  io.close(fd)
end
