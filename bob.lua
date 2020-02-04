-- FIXME: arc range bug - range arc not 1pixel correct
-- FIXME: cutoff indicator and visuals (as with delaytime, pshift/fshift) when not on page 1
-- scriptname: bob
-- v1.2.0 @jah

engine.name = 'R'

Rbob = require('lib/rbob')
RoarFormatters = include('lib/formatters')
Common = include('lib/common')

SETTINGS_FILE = "bob.data"

local cutoff_poll -- TODO: to be integrated to lib/rbob

function init()
  Rbob.init()

  init_polls()
  init_params()
  init_ui()

  load_settings_and_params()

  cutoff_poll:start()
  Common.start_ui()
end

function init_polls()
  cutoff_poll = poll.set("poll1", function(value)
    Rbob.push_cutoff_visual_value(value)
    Common.set_ui_dirty()
  end)

  cutoff_poll.time = 1/FPS
end

function init_params()
  for i,param in ipairs(Rbob.params) do
    params:add(param)
  end
end

function init_ui()
  Common.init_ui {
    arc = { device = arc.connect() },
    pages = {
      {
        {
          label="CUTOFF",
          id="cutoff",
          format=function(id)
            return RoarFormatters.adaptive_freq(params:get(id))
          end,
          visual_values = Rbob.cutoff_visual_values
        },
        {
          label="RES",
          id="resonance",
          format=function(id)
            return RoarFormatters.percentage(params:get(id))
          end
        }
      },
      {
        {
          label="LFO",
          id="lfo_rate",
          format=function(id)
            return RoarFormatters.adaptive_freq(params:get(id))
          end
        },
        {
          label="L>FRQ",
          id="lfo_to_cutoff",
          format=function(id)
            return RoarFormatters.percentage(params:get(id))
          end
        }
      },
      {
        {
          label="E.ATK",
          id="envf_attack",
          format=function(id)
            return RoarFormatters.adaptive_time(params:get(id))
          end
        },
        {
          label="E.DEC",
          id="envf_decay",
          format=function(id)
            return RoarFormatters.adaptive_time(params:get(id))
          end
        },
      },
      {
        {
          label="E.SNS",
          id="envf_sensitivity",
          format=function(id)
            return RoarFormatters.percentage(params:get(id))
          end
        },
        {
          label="E>FRQ",
          id="env_to_cutoff",
          format=function(id)
            return RoarFormatters.percentage(params:get(id))
          end
        }
      }
    }
  }
end

function load_settings_and_params()
  Common.load_settings(SETTINGS_FILE)
  params:read()
  params:bang()
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
