-- scriptname: skev
-- v1.2.0 @jah

engine.name = 'R'

SETTINGS_FILE = "skev.data"

R = require('r/lib/r') -- assumes r engine resides in ~/dust/code/r folder
Formatters = require('formatters')
UI = include('lib/ui')
RoarFormatters = include('lib/formatters')
include('lib/common')

function init()
  init_r()
  init_params()
  init_ui()

  load_settings()
  load_params()

  start_ui()
end

function init_r()
  create_modules()
  connect_modules()
end

function create_modules()
  engine.new("LFO", "MultiLFO")
  engine.new("SoundIn", "SoundIn")
  engine.new("PitchShift", "PShift")
  engine.new("FreqShift", "FShift")
  engine.new("SoundOut", "SoundOut")
end

function connect_modules()
  engine.connect("LFO/Sine", "FreqShift/FM")
  engine.connect("LFO/Sine", "PitchShift/PitchRatioModulation")

  engine.connect("SoundIn/Left", "PitchShift/Left")
  engine.connect("SoundIn/Right", "PitchShift/Right")
  engine.connect("PitchShift/Left", "FreqShift/Left")
  engine.connect("PitchShift/Right", "FreqShift/Right")
  engine.connect("FreqShift/Left", "SoundOut/Left")
  engine.connect("FreqShift/Right", "SoundOut/Right")
end

function init_params()
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

function init_ui()
  UI.init_arc {
    device = arc.connect(),
    on_delta = function(n, delta)
      arc_delta(n, delta)
    end,
    on_refresh = function(my_arc)
      my_arc:all(0)
      my_arc:led(1, util.round(params:get_raw(get_param_id_for_current_page(1))*64), 15)
      my_arc:led(2, util.round(params:get_raw(get_param_id_for_current_page(2))*64), 15)
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
        label="P.SHIFT",
        id="pitch_ratio",
        format=function(id)
          return params:string(id)
        end
      },
      {
        label="F.SHIFT",
        id="freq_shift",
        format=function(id)
          return params:string(id)
        end
      }
    },
    {
      {
        label="P.DISP",
        id="pitch_dispersion",
        format=function(id)
          return params:string(id)
        end
      },
      {
        label="T.DISP",
        id="time_dispersion",
        format=function(id)
          return params:string(id)
        end
      }
    },
    {
      {
        label="LFO.HZ",
        id="lfo_rate",
        format=function(id)
          return params:string(id)
        end
      },
      {
        label="L.SHP",
        id="lfo_rate",
        format=function(id)
          return params:string(id)
        end
      }
    },
    {
      {
        label=">P.RAT",
        id="lfo_to_pitch_ratio",
        format=function(id)
          return RoarFormatters.percentage(params:get(id))
        end
      },
      {
        label=">F.SHFT",
        id="lfo_to_freq_shift",
        format=function(id)
          return params:string(id)
        end
      }
    }
  }
end

function load_params()
  params:read()
  params:bang()
end

function cleanup()
  save_settings()
  params:write()
end
