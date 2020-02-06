-- scriptname: skev
-- v1.2.0 @jah

engine.name = 'R'

RSkev = include('lib/r_skev')

Formatters = include('lib/formatters') -- TODO: test that this can be a local
Common = include('lib/common') -- TODO: test that this can be a local

SETTINGS_FILE = "rymd.data"

freq_shift_visual_values = Common.new_capped_list(util.round(FPS/20)) -- TODO = 2
pitch_ratio_visual_values = Common.new_capped_list(util.round(FPS/20)) -- TODO = 2

function init()
  local r_polls, r_params = RSkev.init(util.round(FPS/20))

  Common.init_polls(r_polls)
  Common.init_params(r_params)
  init_ui()
  load_settings_and_params()
  start_polls()
  start_ui()
end

function init_ui()
  Common.init_ui {
    arc = { device = arc.connect() },
    pages = {
      {
        {
          label="F.SHFT",
          id="freq_shift",
          format=function(id)
            return Formatters.adaptive_freq(params:get(id))
          end,
          visual_values = freq_shift_visual_values
        },
        {
          label="P.RAT",
          id="pitch_ratio",
          format=function(id)
            return Formatters.percentage(params:get(id))
          end,
          visual_values = pitch_ratio_visual_values
        }
      },
      {
        {
          label="P.DISP",
          id="pitch_dispersion",
          format=function(id)
            return Formatters.percentage(params:get(id))
          end
        },
        {
          label="T.DISP",
          id="time_dispersion",
          format=function(id)
            return Formatters.percentage(params:get(id))
          end
        }
      },
      {
        {
          label="LFO.HZ",
          id="lfo_rate",
          format=function(id)
            return Formatters.adaptive_freq(params:get(id))
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
            return Formatters.percentage(params:get(id))
          end
        },
        {
          label=">P.RAT",
          id="lfo_to_pitch_ratio",
          format=function(id)
            return Formatters.percentage(params:get(id))
          end
        }
      }
    }
  }
end

function load_params()
  params:read()
  params:bang()
end

function start_polls()
  for i,script_poll in ipairs(script_polls) do
    script_poll:start()
  end
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
