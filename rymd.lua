-- scriptname: rymd
-- v1.2.0 @jah

engine.name = 'R'

SETTINGS_FILE = "bob.data"

R = require('r/lib/r') -- assumes r engine resides in ~/dust/code/r folder
ControlSpec = require('controlspec')
Formatters = require('formatters')
UI = include('lib/ui')
RoarFormatters = include('lib/formatters')
include('lib/common') -- defines redraw, enc, key and other global functions

function init()
  create_modules()
  set_static_module_params()
  connect_modules()

  init_params()
  init_ui()

  load_settings()
  load_params()

  ui_run_ui()
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

function init_params()
  params:add {
    type="control",
    id="direct",
    name="Direct",
    controlspec=R.specs.SGain.Gain,
    action=function (value)
      engine.set("Direct.Gain", value)
      UI.set_dirty()
    end
  }

  local delay_send_spec = R.specs.SGain.Gain
  delay_send_spec.default = -10

  params:add {
    type="control",
    id="delay_send",
    name="Delay Send",
    controlspec=delay_send_spec,
    action=function (value)
      engine.set("FXSend.Gain", value)
      UI.set_dirty()
    end
  }

  local delay_time_left_spec = R.specs.Delay.DelayTime
  delay_time_left_spec.default = 400

  params:add {
    type="control",
    id="delay_time_left",
    name="Delay Time Left",
    controlspec=delay_time_left_spec,
    action=function (value)
      engine.set("Delay1.DelayTime", value)
      UI.set_dirty()
    end
  }

  local delay_time_right_spec = R.specs.Delay.DelayTime
  delay_time_right_spec.default = 300

  params:add {
    type="control",
    id="delay_time_right",
    name="Delay Time Right",
    controlspec=delay_time_right_spec,
    action=function (value)
      engine.set("Delay2.DelayTime", value)
      UI.set_dirty()
    end
  }

  local filter_spec = R.specs.MMFilter.Frequency:copy()
  filter_spec.default = 4000
  filter_spec.maxval = 10000

  params:add {
    type="control",
    id="damping",
    name="Damping",
    controlspec=filter_spec,
    action=function(value)
      engine.set("Filter1.Frequency", value)
      engine.set("Filter2.Frequency", value)
      UI.set_dirty()
    end
  }

  local feedback_spec = R.specs.SGain.Gain:copy()
  feedback_spec.default = -10
  feedback_spec.maxval = 0

  params:add {
    type="control",
    id="feedback",
    name="Feedback",
    controlspec=feedback_spec,
    action=function (value)
      engine.set("Feedback.Gain", value)
      UI.set_dirty()
    end
  }

  params:add {
    type="control",
    id="mod_rate",
    name="Mod Rate",
    controlspec=R.specs.MultiLFO.Frequency,
    formatter=Formatters.round(0.001),
    action=function (value)
      engine.set("LFO.Frequency", value)
      UI.set_dirty()
    end
  }

  params:add {
    type="control",
    id="delay_time_mod_depth",
    name="Delay Time Mod Depth",
    controlspec=ControlSpec.UNIPOLAR,
    formatter=Formatters.percentage,
    action=function(value)
      engine.set("Delay1.DelayTimeModulation", value)
      engine.set("Delay2.DelayTimeModulation", value)
      UI.set_dirty()
    end
  }
end

function init_ui()
  UI.init_arc {
    device = arc.connect(),
    on_delta = function(n, delta)
      arc_delta(n, delta)
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
        label="DIR",
        id="direct",
        format=function(id)
          return params:get(id)
        end
      },
      {
        label="SEND",
        id="delay_send",
        format=function(id)
          return params:get(id)
        end
      }
    },
    {
      {
        label="L.TIME",
        id="delay_time_left",
        format=function(id)
          return RoarFormatters.adaptive_time(params:get(id))
        end
      },
      {
        label="R.TIME",
        id="delay_time_right",
        format=function(id)
          return RoarFormatters.adaptive_time(params:get(id))
        end
      }
    },
    {
      {
        label="DAMP",
        id="damping",
        format=function(id)
          return RoarFormatters.adaptive_freq(params:get(id))
        end
      },
      {
        label="FBK",
        id="feedback",
        format=function(id)
          return params:get(id)
        end
      }
    },
    {
      {
        label="RATE",
        id="mod_rate",
        format=function(id)
          return RoarFormatters.adaptive_freq(params:get(id))
        end
      },
      {
        label="MOD",
        id="delay_time_mod_depth",
        format=function(id)
          return RoarFormatters.percentage(params:get(id))
        end
      }
    },
  }
end

function load_settings()
  local fd=io.open(norns.state.data .. SETTINGS_FILE,"r")
  local page
  if fd then
    io.input(fd)
    local str = io.read()
    io.close(fd)
    if str ~= "" then
      page = tonumber(str)
    end
  end
  set_page(page or 1)
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
  io.write(get_page() .. "\n")
  io.close(fd)
end
