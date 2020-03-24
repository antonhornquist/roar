-- scriptname: bob
-- v1.3.0 @jah

engine.name = 'R'

RBob = include('lib/r_bob')
Formatters = include('lib/formatters')
Common = include('lib/common')

SETTINGS_FILE = "bob.data"
FPS = 35

function init()
  r_polls, visual_values, r_params = RBob.init(util.round(FPS/20))

  ui = {
    arc = { device = arc.connect() },
    pages = {
      {
        {
          label="CUTOFF",
          id="cutoff",
          formatter=Formatters.adaptive_freq,
          visual_values = visual_values.cutoff
        },
        {
          label="RES",
          id="resonance",
          formatter=Formatters.percentage
        }
      },
      {
        {
          label="LFO",
          id="lfo_rate",
          formatter=Formatters.adaptive_freq
        },
        {
          label="L>FRQ",
          id="lfo_to_cutoff",
          formatter=Formatters.percentage
        }
      },
      {
        {
          label="E.ATK",
          id="envf_attack",
          formatter=Formatters.adaptive_time
        },
        {
          label="E.DEC",
          id="envf_decay",
          formatter=Formatters.adaptive_time
        },
      },
      {
        {
          label="E.SNS",
          id="envf_sensitivity",
          formatter=Formatters.percentage
        },
        {
          label="E>FRQ",
          id="env_to_cutoff",
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
  Common.redraw() -- TODO: pass screen

  -- TODO: cutoff indicator and visuals (as with delaytime, pshift/fshift) when not on page 1
end

function enc(n, delta)
  Common.enc(n, delta)
end

function key(n, z)
  Common.key(n, z)
end
