-- scriptname: skev
-- v1.1.1 @jah

engine.name = 'R'

local Formatters = require('formatters')
local R = require('r/lib/r') -- assumes r engine resides in ~/dust/code/r folder
local UI = include('lib/ui')
local Pages = include('lib/pages')

local fps = 120

local function create_modules()
  engine.new("LFO", "MultiLFO")
  engine.new("SoundIn", "SoundIn")
  engine.new("PitchShift", "PShift")
  engine.new("FreqShift", "FShift")
  engine.new("SoundOut", "SoundOut")
end

local function connect_modules()
  engine.connect("LFO/Sine", "FreqShift/FM")
  engine.connect("LFO/Sine", "PitchShift/PitchRatioModulation")

  engine.connect("SoundIn/Left", "PitchShift/Left")
  engine.connect("SoundIn/Right", "PitchShift/Right")
  engine.connect("PitchShift/Left", "FreqShift/Left")
  engine.connect("PitchShift/Right", "FreqShift/Right")
  engine.connect("FreqShift/Left", "SoundOut/Left")
  engine.connect("FreqShift/Right", "SoundOut/Right")
end

local function init_params()
  params:add {
    type="control",
    id="pitch_ratio",
    name="Pitch Ratio",
    formatter=Formatters.percentage,
    controlspec=R.specs.PShift.PitchRatio,
    action=function (value)
      engine.set("PitchShift.PitchRatio", value)
      UI.set_dirty()
    end
  }

  params:add {
    type="control",
    id="freq_shift",
    name="Freq Shift",
    controlspec=R.specs.FShift.Frequency,
    action=function (value)
      engine.set("FreqShift.Frequency", value)
      UI.set_dirty()
    end
  }

  params:add {
    type="control",
    id="pitch_dispersion",
    name="Pitch Dispersion",
    formatter=Formatters.percentage,
    controlspec=R.specs.PShift.PitchDispersion,
    action=function (value)
      engine.set("PitchShift.PitchDispersion", value)
      UI.set_dirty()
    end
  }

  params:add {
    type="control",
    id="time_dispersion",
    name="Time Dispersion",
    formatter=Formatters.percentage,
    controlspec=R.specs.PShift.TimeDispersion,
    action=function (value)
      engine.set("PitchShift.TimeDispersion", value)
      UI.set_dirty()
    end
  }

  params:add {
    type="control",
    id="lfo_rate",
    name="LFO Rate",
    formatter=Formatters.round(0.001),
    controlspec=R.specs.MultiLFO.Frequency,
    action=function (value)
      engine.set("LFO.Frequency", value)
      UI.set_dirty()
    end
  }

  params:add {
    type="control",
    id="lfo_to_freq_shift",
    name="LFO > Freq Shift",
    formatter=Formatters.percentage,
    controlspec=R.specs.FShift.FM,
    action=function (value)
      engine.set("FreqShift.FM", value)
      UI.set_dirty()
    end
  }

  params:add {
    type="control",
    id="lfo_to_pitch_ratio",
    name="LFO > Pitch Ratio",
    formatter=Formatters.percentage,
    controlspec=R.specs.PShift.PitchRatioModulation,
    action=function (value)
      engine.set("PitchShift.PitchRatioModulation", value)
      UI.set_dirty()
    end
  }
end

local function refresh_ui()
  Pages.refresh(UI)
  UI.refresh()
end

local function init_pages()
  local ui_params = {
    {
      {
        label="P.SHIFT",
        id="pitch_ratio",
        value=function(id)
          return params:string(id)
        end
      },
      {
        label="F.SHIFT",
        id="freq_shift",
        value=function(id)
          return params:string(id)
        end
      }
    },
    {
      {
        label="P.DISP",
        id="pitch_dispersion",
        value=function(id)
          return params:string(id)
        end
      },
      {
        label="T.DISP",
        id="time_dispersion",
        value=function(id)
          return params:string(id)
        end
      }
    },
    {
      {
        label="LFO.HZ",
        id="lfo_rate",
        value=function(id)
          return params:string(id)
        end
      },
      {
        label="L.SHP",
        id="lfo_rate",
        value=function(id)
          return params:string(id)
        end
      }
    },
    {
      {
        label=">P.RAT",
        id="lfo_to_pitch_ratio",
        value=function(id)
          return params:string(id)
        end
      },
      {
        label=">F.SHFT",
        id="lfo_to_freq_shift",
        value=function(id)
          return params:string(id)
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
