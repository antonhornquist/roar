-- scriptname: bob
-- v1.2.0 @jah

engine.name = 'R'

local Formatters = require('formatters')
local R = require('r/lib/r') -- assumes r engine resides in ~/dust/code/r folder
local UI = include('lib/ui')
local Pages = include('lib/pages')

local fps = 120

local function create_modules()
  engine.new("LFO", "MultiLFO")
  engine.new("SoundIn", "SoundIn")
  engine.new("FilterL", "LPLadder")
  engine.new("FilterR", "LPLadder")
  engine.new("SoundOut", "SoundOut")
end

local function connect_modules()
  engine.connect("SoundIn/Left", "FilterL/In")
  engine.connect("SoundIn/Right", "FilterR/In")
  engine.connect("LFO/Sine", "FilterL/FM")
  engine.connect("LFO/Sine", "FilterR/FM")
  engine.connect("FilterL/Out", "SoundOut/Left")
  engine.connect("FilterR/Out", "SoundOut/Right")
end

local function init_params()
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

local function refresh_ui()
  Pages.refresh(UI)
  UI.refresh()
end

local function init_pages()
  local function format_percentage(value)
    return util.round(value*100, 1) .. "%"
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
        label="FREQ",
        id="cutoff",
        value=function(id)
          return format_freq(params:get(id))
        end
      },
      {
        label="RES",
        id="resonance",
        value=function(id)
          return format_percentage(params:get(id))
        end
      }
    },
    {
      {
        label="LFO",
        id="lfo_rate",
        value=function(id)
          return format_freq(params:get(id))
        end
      },
      {
        label="L>FRQ",
        id="lfo_to_cutoff",
        value=function(id)
          return format_percentage(params:get(id))
        end
      }
    }
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
      my_arc:led(1, util.round(params:get_raw(Pages.get_current_page_param_id(1))*64), 15)
      my_arc:led(2, util.round(params:get_raw(Pages.get_current_page_param_id(2))*64), 15)
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
