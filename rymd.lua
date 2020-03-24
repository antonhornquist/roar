-- scriptname: rymd
-- v1.2.0 @jah

engine.name = 'R'

RRymd = include('lib/r_rymd')
Formatters = include('lib/formatters')
Common = include('lib/common')

SETTINGS_FILE = "rymd.data"
FPS = 35

function init()
  r_polls, visual_values, r_params = RRymd.init(util.round(FPS/20))

  ui = {
    arc = { device = arc.connect() },
    pages = {
      {
        {
          label="DIR",
          id="direct",
          formatter=Formatters.adaptive_db
        },
        {
          label="SEND",
          id="delay_send",
          formatter=Formatters.adaptive_db
        }
      },
      {
        {
          label="L.TIME",
          id="delay_time_left",
          formatter=Formatters.adaptive_time,
          visual_values = visual_values.delay_time_left
        },
        {
          label="R.TIME",
          id="delay_time_right",
          formatter=Formatters.adaptive_time,
          visual_values = visual_values.delay_time_right
        }
      },
      {
        {
          label="DAMP",
          id="damping",
          formatter=Formatters.adaptive_freq
        },
        {
          label="FBK",
          id="feedback",
          formatter=function(param)
            return util.round(param:get_raw()*100, 1).."%"
          end
        }
      },
      {
        {
          label="RATE",
          id="mod_rate",
          formatter=Formatters.adaptive_freq
        },
        {
          label="MOD",
          id="delay_time_mod_depth",
          formatter=Formatters.percentage
        }
      },
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
