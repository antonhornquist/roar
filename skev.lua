-- scriptname: skev
-- v1.2.0 @jah

engine.name = 'R'

RSkev = include('lib/r_skev')
Formatters = include('lib/formatters')
Common = include('lib/common')

SETTINGS_FILE = "skev.data"
FPS = 35

function init()
  r_polls, visual_values, r_params = RSkev.init(util.round(FPS/20))

  ui = {
    arc = { device = arc.connect() },
    pages = {
      {
        {
          label="F.SHFT",
          id="freq_shift",
          formatter=Formatters.adaptive_freq,
          visual_values = visual_values.freq_shift
        },
        {
          label="P.RAT",
          id="pitch_ratio",
          formatter=Formatters.percentage,
          visual_values = visual_values.pitch_ratio
        }
      },
      {
        {
          label="P.DISP",
          id="pitch_dispersion",
          formatter=Formatters.percentage
        },
        {
          label="T.DISP",
          id="time_dispersion",
          formatter=Formatters.percentage
        }
      },
      {
        {
          label="LFO.HZ",
          id="lfo_rate",
          formatter=Formatters.adaptive_freq
        },
        {
          label="L.SHP",
          id="lfo_rate",
          formatter=function(param)
            return "N/A"
          end
        }
      },
      {
        {
          label=">F.SHFT",
          id="lfo_to_freq_shift",
          formatter=Formatters.percentage
        },
        {
          label=">P.RAT",
          id="lfo_to_pitch_ratio",
          formatter=Formatters.percentage
        }
      }
    }
  }

  Common.init(r_polls, r_params, ui, SETTINGS_FILE, FPS)
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
