-- FIXME: arc range bug - range arc not 1pixel correct
-- FIXME: cutoff indicator and visuals (as with delaytime, pshift/fshift) when not on page 1
-- scriptname: bob
-- v1.2.0 @jah

engine.name = 'R'

Formatters = include('lib/formatters')
Common = include('lib/common')
RBob = include('lib/r_bob')

SETTINGS_FILE = "bob.data"

function init()
  local bob_params, bob_polls = RBob.init()

  init_polls(bob_polls)
  init_params(bob_params)
  init_ui()
  load_settings_and_params()
  start_polls()
  start_ui()
end

function init_polls(bob_polls)
  script_polls = {}

  for i,bob_poll in ipairs(bob_polls) do
    local script_poll
    script_poll = poll.set("poll" .. i, function(value)
      bob_poll.handler(value)
      Common.set_ui_dirty()
    end)

    script_poll.time = 1/FPS
    table.insert(script_polls, script_poll)
  end
end

function init_params(bob_params)
  print("----")
  for i,bob_param in ipairs(bob_params) do
    print(bob_param.id)
    -- TODO params:add(bob_param)
    params:add {
      type=bob_param.type,
      id=bob_param.id,
      name=bob_param.name,
      controlspec=bob_param.controlspec,
      action=function (value)
        bob_param.action(value)
        Common.set_ui_dirty()
      end
    }
  end
  print("----")
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

function start_ui()
  Common.start_ui()
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
