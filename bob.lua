-- FIXME: arc range bug - range arc not 1pixel correct
-- FIXME: cutoff indicator and visuals (as with delaytime, pshift/fshift) when not on page 1
-- scriptname: bob
-- v1.2.0 @jah

engine.name = 'R'

local RBob = include('lib/r_bob')
local Formatters = include('lib/formatters')
local Common = include('lib/common')

SETTINGS_FILE = "bob.data"

function init()
  r_polls, visual_values, r_params = RBob.init(util.round(FPS/20))

  ui = {
    arc = { device = arc.connect() },
    pages = {
      {
        {
          label="CUTOFF",
          id="cutoff",
          format=function(id)
            return Formatters.adaptive_freq(params:get(id))
          end,
          visual_values = visual_values.cutoff
        },
        {
          label="RES",
          id="resonance",
          format=function(id)
            return Formatters.percentage(params:get(id))
          end
        }
      },
      {
        {
          label="LFO",
          id="lfo_rate",
          format=function(id)
            return Formatters.adaptive_freq(params:get(id))
          end
        },
        {
          label="L>FRQ",
          id="lfo_to_cutoff",
          format=function(id)
            return Formatters.percentage(params:get(id))
          end
        }
      },
      {
        {
          label="E.ATK",
          id="envf_attack",
          format=function(id)
            return Formatters.adaptive_time(params:get(id))
          end
        },
        {
          label="E.DEC",
          id="envf_decay",
          format=function(id)
            return Formatters.adaptive_time(params:get(id))
          end
        },
      },
      {
        {
          label="E.SNS",
          id="envf_sensitivity",
          format=function(id)
            return Formatters.percentage(params:get(id))
          end
        },
        {
          label="E>FRQ",
          id="env_to_cutoff",
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
