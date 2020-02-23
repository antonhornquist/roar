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
          format=function(id)
            return Formatters.adaptive_db(params:get(id))
          end
        },
        {
          label="SEND",
          id="delay_send",
          format=function(id)
            return Formatters.adaptive_db(params:get(id))
          end
        }
      },
      {
        {
          label="L.TIME",
          id="delay_time_left",
          format=function(id)
            return Formatters.adaptive_time(params:get(id))
          end,
          visual_values = visual_values.delay_time_left
        },
        {
          label="R.TIME",
          id="delay_time_right",
          format=function(id)
            return Formatters.adaptive_time(params:get(id))
          end,
          visual_values = visual_values.delay_time_right
        }
      },
      {
        {
          label="DAMP",
          id="damping",
          format=function(id)
            return Formatters.adaptive_freq(params:get(id))
          end
        },
        {
          label="FBK",
          id="feedback",
          format=function(id)
            return util.round(params:get_raw(id)*100, 1).."%"
          end
        }
      },
      {
        {
          label="RATE",
          id="mod_rate",
          format=function(id)
            return Formatters.adaptive_freq(params:get(id))
          end
        },
        {
          label="MOD",
          id="delay_time_mod_depth",
          format=function(id)
            return Formatters.percentage(params:get(id))
          end
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
