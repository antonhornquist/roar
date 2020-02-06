-- FIXME: arc range bug - range arc not 1pixel correct
-- FIXME: cutoff indicator and visuals (as with delaytime, pshift/fshift) when not on page 1
-- scriptname: bob
-- v1.2.0 @jah

engine.name = 'R'

RBob = include('lib/r_bob')

Formatters = include('lib/formatters') -- TODO: test that this can be a local
Common = include('lib/common') -- TODO: test that this can be a local

SETTINGS_FILE = "bob.data"

function init()
  local r_polls, r_params = RBob.init(util.round(FPS/20))

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
          label="CUTOFF",
          id="cutoff",
          format=function(id)
            return Formatters.adaptive_freq(params:get(id))
          end,
          visual_values = RBob.visual_values.cutoff
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
