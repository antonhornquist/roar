-- scriptname: rymd
-- v1.2.0 @jah

engine.name = 'R'

RRymd = include('lib/r_rymd')

Formatters = include('lib/formatters') -- TODO: test that this can be a local
Common = include('lib/common') -- TODO: test that this can be a local

SETTINGS_FILE = "rymd.data"

function init()
  local r_polls, r_params = RRymd.init(util.round(FPS/20))

  Common.init_polls(r_polls)
  Common.init_params(r_params)
  init_ui()
  load_settings_and_params()
  start_polls()
  Common.start_ui()
end

function init_ui()
  Common.init_ui {
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
          visual_values = RRymd.visual_values.delay_time_left
        },
        {
          label="R.TIME",
          id="delay_time_right",
          format=function(id)
            return Formatters.adaptive_time(params:get(id))
          end,
          visual_values = RRymd.visual_values.delay_time_right
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
            return Formatters.adaptive_db(params:get(id))
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
end

function load_settings_and_params()
  Common.load_settings(SETTINGS_FILE)
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
