-- scriptname: rymd
-- v1.1.0 @jah

engine.name = 'R'

local ControlSpec = require 'controlspec'
local Formatters = require 'formatters'
local R = require('r/lib/r') -- assumes r engine resides in ~/dust/code/r folder
local UI = include('lib/ui')
local Pages = include('lib/pages')

local fine = false -- TODO
local fps = 120

local function create_modules()
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

local function set_static_module_params()
  engine.set("Filter1.Resonance", 0.1)
  engine.set("Filter2.Resonance", 0.1)
end

local function connect_modules()
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

local function init_params()
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

local function refresh_ui()
  Pages.refresh(UI)
  UI.refresh()
end

local function init_pages()
  local function format_percentage(value)
    return util.round(value*100, 1) .. "%"
  end

  local function format_time(ms)
    if util.round(ms, 1) < 1000 then
      return util.round(ms, 1) .. "ms"
    elseif util.round(ms, 1) < 10000 then
      return util.round(ms/1000, 0.01) .. "s"
    else
      return util.round(ms/1000, 0.1) .. "s"
    end
  end

  local function format_freq(hz)
    if hz < 1 then
      local str = tostring(util.round(hz, 0.001))
      return string.sub(str, 2, #str).."Hz"
    elseif hz < 10 then
      return util.round(hz, 0.01).."Hz"
    elseif hz < 100 then
      return util.round(hz, 0.1).."Hz"
    elseif hz < 1000 then
      return util.round(hz, 1).."Hz"
    elseif hz < 10000 then
      return util.round(hz/1000, 0.1) .. "kHz"
    else
      return util.round(hz/1000, 1) .. "kHz"
    end
  end

  local ui_params = {
    {
      {
        label="DIR",
        id="direct",
        value=function(id)
          return params:get(id)
        end
      },
      {
        label="SEND",
        id="delay_send",
        value=function(id)
          return params:get(id)
        end
      }
    },
    {
      {
        label="L.TIME",
        id="delay_time_left",
        value=function(id)
          return format_time(params:get(id))
        end
      },
      {
        label="R.TIME",
        id="delay_time_right",
        value=function(id)
          return format_time(params:get(id))
        end
      }
    },
    {
      {
        label="DAMP",
        id="damping",
        value=function(id)
          return format_freq(params:get(id))
        end
      },
      {
        label="FBK",
        id="feedback",
        value=function(id)
          return params:get(id)
        end
      }
    },
    {
      {
        label="RATE",
        id="mod_rate",
        value=function(id)
          return format_freq(params:get(id))
        end
      },
      {
        label="MOD",
        id="delay_time_mod_depth",
        value=function(id)
          return format_percentage(params:get(id))
        end
      }
    },
  }

  Pages.init(ui_params, fps)
end

local function init_ui_refresh_metro()
  local ui_refresh_metro = metro.init()
  ui_refresh_metro.event = refresh_ui
  ui_refresh_metro.time = 1/fps
  ui_refresh_metro:start()
end

local function init_ui()
  UI.init_arc {
    device = arc.connect(),
    on_delta = function(n, delta)
      local d
      if fine then
        d = delta/5
      else
        d = delta
      end
      change_current_page_param_raw_delta(n, d/500)
    end,
    on_refresh = function(my_arc)
      my_arc:all(0)
      my_arc:led(1, util.round(params:get_raw(get_current_page_param_id(1))*64), 15)
      my_arc:led(2, util.round(params:get_raw(get_current_page_param_id(2))*64), 15)
    end
  }

  UI.init_screen {
    on_refresh = function()
      redraw()
    end
  }

  init_ui_refresh_metro()
end

function init()
  create_modules()
  set_static_module_params()
  connect_modules()

  init_params()
  init_ui()
  init_pages()

  params:read()
  params:bang()
end

function cleanup()
  params:write()
end

function redraw()
  Pages.redraw(screen, UI)
end

function change_current_page_param_delta(n, delta)
  params:delta(Pages.get_current_page_param_id(n), delta)
end

function change_current_page_param_raw_delta(n, rawdelta)
  local id = Pages.get_current_page_param_id(n)
  local val = params:get_raw(id)
  params:set_raw(id, val+rawdelta)
end

function enc(n, delta)
  local d
  if fine then
    d = delta/5
  else
    d = delta
  end
  if n == 1 then
    mix:delta("output", d)
    UI.screen_dirty = true
  else
    change_current_page_param_delta(n-1, d)
  end
end

function key(n, z)
  Pages.key(n, z, UI)
end
