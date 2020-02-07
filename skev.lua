-- scriptname: skev
-- v1.2.0 @jah

engine.name = 'R'

RSkev = include('lib/r_skev')
Formatters = include('lib/formatters')
Common = include('lib/common')

SETTINGS_FILE = "skev.data"

function init()
  r_polls, visual_values, r_params = RSkev.init(util.round(FPS/20))

  ui = {
    arc = { device = arc.connect() },
    pages = {
      {
        {
          label="F.SHFT",
          id="freq_shift",
          format=function(id)
            return Formatters.adaptive_freq(params:get(id))
          end,
          visual_values = visual_values.freq_shift
        },
        {
          label="P.RAT",
          id="pitch_ratio",
          format=function(id)
            return Formatters.percentage(params:get(id))
          end,
          visual_values = visual_values.pitch_ratio
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

  Common.init(r_polls, r_params, ui, SETTINGS_FILE)
end

function cleanup()
  Common.cleanup(SETTINGS_FILE)
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
