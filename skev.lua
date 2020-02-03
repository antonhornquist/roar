-- scriptname: skev
-- v1.2.0 @jah

engine.name = 'R'

SETTINGS_FILE = "skev.data"

R = require('r/lib/r') -- assumes r engine resides in ~/dust/code/r folder
Formatters = require('formatters')
UI = include('lib/ui')
RoarFormatters = include('lib/formatters')
Common = include('lib/common')

function init()
  init_r()
  init_polls()
  init_params()
  init_ui()

  Common.load_settings(SETTINGS_FILE)
  load_params()

  start_polls()
  Common.start_ui()
end

function init_r()
  create_modules()
  connect_modules()
  engine.pollvisual(0, "FreqShift.Frequency") -- TODO: should be indexed from 1
  engine.pollvisual(1, "PitchShift.PitchRatio") -- TODO: should be indexed from 1
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

function init_polls()
  freq_shift_poll = poll.set("poll1", function(value)
    local freq_shift_page_param = page_params[1][1]
    local visual_values = freq_shift_page_param.visual_values
    local visual_value = R.specs.FShift.Frequency:unmap(value) -- TODO: establish visual specs in lua module
    Common.push_to_capped_list(visual_values, visual_value)
    UI.set_dirty()
  end)

  freq_shift_poll.time = 1/FPS

  pitch_ratio_poll = poll.set("poll2", function(value)
    local pitch_ratio_page_param = page_params[1][2]
    local visual_values = pitch_ratio_page_param.visual_values
    local visual_value = R.specs.PShift.PitchRatio:unmap(value) -- TODO: establish visual specs in lua module
    Common.push_to_capped_list(visual_values, visual_value)
    UI.set_dirty()
  end)

  pitch_ratio_poll.time = 1/FPS

end

function init_params()
  params:add {
    type="control",
    id="freq_shift",
    name="Freq Shift",
    controlspec=R.specs.FShift.Frequency,
    action=function (value)
      engine.set("FreqShift.Frequency", value)
      page_params[1][1].ind_ref = params:get_raw("freq_shift")
      UI.set_dirty()
    end
  }

  params:add {
    type="control",
    id="pitch_ratio",
    name="Pitch Ratio",
    formatter=Formatters.percentage,
    controlspec=R.specs.PShift.PitchRatio,
    action=function (value)
      engine.set("PitchShift.PitchRatio", value)
      page_params[1][2].ind_ref = params:get_raw("pitch_ratio")
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
      page_params[2][1].ind_ref = params:get_raw("pitch_dispersion")
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
      page_params[2][2].ind_ref = params:get_raw("time_dispersion")
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
      page_params[3][1].ind_ref = params:get_raw("lfo_rate")
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
      page_params[4][1].ind_ref = params:get_raw("lfo_to_freq_shift")
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
      page_params[4][2].ind_ref = params:get_raw("lfo_to_pitch_ratio")
      UI.set_dirty()
    end
  }
end

function init_ui()
  UI.init_arc {
    device = arc.connect(),
    on_delta = function(n, delta)
      Common.arc_delta(n, delta)
    end,
    on_refresh = function(my_arc)
      local page_param_tuple = page_params[Common.get_page()]

      Common.draw_arc(
        my_arc,
        params:get_raw(get_param_id_for_current_page(1)),
        page_param_tuple[1].visual_values,
        params:get_raw(get_param_id_for_current_page(2)),
        page_param_tuple[2].visual_values
      )
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
        label="F.SHFT",
        id="freq_shift",
        format=function(id)
          return RoarFormatters.adaptive_freq(params:get(id))
        end,
        visual_values = Common.new_capped_list(util.round(FPS/20)) -- TODO = 2
      },
      {
        label="P.RAT",
        id="pitch_ratio",
        format=function(id)
          return RoarFormatters.percentage(params:get(id))
        end,
        visual_values = Common.new_capped_list(util.round(FPS/20)) -- TODO = 2
      }
    },
    {
      {
        label="P.DISP",
        id="pitch_dispersion",
        format=function(id)
          return RoarFormatters.percentage(params:get(id))
        end
      },
      {
        label="T.DISP",
        id="time_dispersion",
        format=function(id)
          return RoarFormatters.percentage(params:get(id))
        end
      }
    },
    {
      {
        label="LFO.HZ",
        id="lfo_rate",
        format=function(id)
          return RoarFormatters.adaptive_freq(params:get(id))
        end
      },
      {
        label="L.SHP",
        id="lfo_rate",
        format=function(id)
          return "N/A"
        end
      }
    },
    {
      {
        label=">F.SHFT",
        id="lfo_to_freq_shift",
        format=function(id)
          return RoarFormatters.percentage(params:get(id))
        end
      },
      {
        label=">P.RAT",
        id="lfo_to_pitch_ratio",
        format=function(id)
          return RoarFormatters.percentage(params:get(id))
        end
      }
    }
  }
end

function load_params()
  params:read()
  params:bang()
end

function start_polls()
  freq_shift_poll:start()
  pitch_ratio_poll:start()
end

function cleanup()
  Common.save_settings(SETTINGS_FILE)
  params:write()
end

function redraw()
  Common.redraw()
end

function enc(n, delta)
  Common.enc(n, delta)
end

function key(n, z)
  Common.key(n, z)
end
