-- scriptname: bob
-- v1.2.0 @jah

engine.name = 'R'

SETTINGS_FILE = "bob.data"

R = require('r/lib/r') -- assumes r engine resides in ~/dust/code/r folder
Formatters = require('formatters')
UI = include('lib/ui')
RoarFormatters = include('lib/formatters')
include('lib/common_ui') -- defines redraw, enc, key and other global functions

function init()
  create_modules()
  connect_modules()

  load_settings()

  init_params()
  load_params()

  init_ui()
end

function create_modules()
  engine.new("LFO", "MultiLFO")
  engine.new("SoundIn", "SoundIn")
  engine.new("FilterL", "LPLadder")
  engine.new("FilterR", "LPLadder")
  engine.new("SoundOut", "SoundOut")
end

function connect_modules()
  engine.connect("SoundIn/Left", "FilterL/In")
  engine.connect("SoundIn/Right", "FilterR/In")
  engine.connect("LFO/Sine", "FilterL/FM")
  engine.connect("LFO/Sine", "FilterR/FM")
  engine.connect("FilterL/Out", "SoundOut/Left")
  engine.connect("FilterR/Out", "SoundOut/Right")
end

function init_params()
  local filter_spec = R.specs.LPLadder.Frequency:copy()
  filter_spec.default = 1000
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

  local resonance_spec = R.specs.LPLadder.Resonance:copy()
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

  local lfo_to_cutoff_spec = R.specs.LPLadder.FM:copy()
  lfo_to_cutoff_spec.default = 0.1

  params:add {
    type="control",
    id="lfo_to_cutoff",
    name="LFO > Cutoff",
    controlspec=lfo_to_cutoff_spec,
    formatter=Formatters.percentage,
    action=function (value)
      engine.set("FilterL.FM", value)
      engine.set("FilterR.FM", value)
      UI.set_dirty()
    end
  }

end

function load_params()
  params:read()
  params:bang()
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
    }
  }

  init_ui_update_metro()
end

function init_ui_update_metro()
  local ui_update_metro = metro.init()
  ui_update_metro.event = ui_update
  ui_update_metro.time = 1/ui_get_fps()
  ui_update_metro:start()
end

function cleanup()
  save_settings()
  params:write()
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

function save_settings()
  local fd=io.open(norns.state.data .. SETTINGS_FILE,"w+")
  io.output(fd)
  io.write(ui_get_page() .. "\n")
  io.close(fd)
end
