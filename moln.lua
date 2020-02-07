-- scriptname: moln
-- v1.3.0 @jah

engine.name = 'R'

RMoln = include('lib/r_moln')
Formatters = include('lib/formatters')
Common = include('lib/common')

SETTINGS_FILE = "moln.data"

engine_ready = false -- TODO

function init()
  r_polls, visual_values, r_params = RMoln.init(util.round(FPS/20))

  ui = {
    arc = { device = arc.connect() },
    --[[
    --TODO: grid_width
    grid = {
      device = grid.connect(),
      on_key = function(x, y, state)
        local function gridkey_to_note(x, y, grid_width)
          if grid_width == 16 then
            return x * 8 + y
          else
            return (4+x) * 8 + y
          end
        end

        if engine_ready then
          local note = gridkey_to_note(x, y, UI.grid_width)
          if state == 1 then
            RMoln.note_on(note, 5)
          else
            RMoln.note_off(note)
          end

          Common.set_ui_dirty()
        end
      end,
      on_refresh = function(my_grid)
        local function note_to_gridkey(note, grid_width)
          if grid_width == 16 then
            return math.floor(note/8), note % 8
          else
            return math.floor(note/8) - 4, note % 8
          end
        end

        my_grid:all(0)
        for voicenum=1,POLYPHONY do
          local note = note_downs[voicenum]
          if note then
            local x, y = note_to_gridkey(note, UI.grid_width)
            my_grid:led(x, y, 15)
          end
        end
      end
    },
    ]]
    midi = {
      device = midi.connect(),
      on_event = function (data)
        if engine_ready then
          if #data == 0 then return end
          local msg = midi.to_msg(data)
          if msg.type == "note_off" then
            RMoln.note_off(msg.note)
          elseif msg.type == "note_on" then
            RMoln.note_on(msg.note, msg.vel / 127)
          end
          Common.set_ui_dirty()
        end
      end
    },
    pages = {
      {
        {
          label="FREQ",
          id="filter_frequency",
          format=function(id)
            return Formatters.adaptive_freq(params:get(id))
          end
        },
        {
          label="RES",
          id="filter_resonance",
          format=function(id)
            return Formatters.percentage(params:get(id))
          end
        }
      },
      {
        {
          label="A.RNG",
          id="osc_a_range",
          format=function(id)
            return Formatters.range(params:get(id))
          end
        },
        {
          label="B.RNG",
          id="osc_b_range",
          format=function(id)
            return Formatters.range(params:get(id))
          end
        }
      },
      {
        {
          label="A.PW",
          id="osc_a_pulsewidth",
          format=function(id)
            return Formatters.percentage(params:get(id))
          end
        },
        {
          label="B.PW",
          id="osc_b_pulsewidth",
          format=function(id)
            return Formatters.percentage(params:get(id))
          end
        }
      },
      {
        {
          label="DETUN",
          id="osc_detune",
          format=function(id)
            return Formatters.percentage(params:get(id))
          end
        },
        {
          label="LFO",
          id="lfo_frequency",
          format=function(id)
            return Formatters.adaptive_freq(params:get(id))
          end
        },
      },
      {
        {
          label="PWM",
          id="lfo_to_osc_pwm",
          format=function(id)
            return Formatters.percentage(params:get(id))
          end
        },
        {
          label="E>FIL",
          id="env_to_filter_fm",
          format=function(id)
            return Formatters.percentage(params:get(id))
          end
        },
      },
      {
        {
          label="E.ATK",
          id="env_attack",
          format=function(id)
            return Formatters.adaptive_time(params:get(id))
          end
        },
        {
          label="E.DEC",
          id="env_decay",
          format=function(id)
            return Formatters.adaptive_time(params:get(id))
          end
        },
      },
      {
        {
          label="E.SUS",
          id="env_sustain",
          format=function(id)
            return Formatters.percentage(params:get(id))
          end
        },
        {
          label="E.REL",
          id="env_release",
          format=function(id)
            return Formatters.adaptive_time(params:get(id))
          end
        }
      }
    }
  }

  start_after_1_second_delay()
end

function start_after_1_second_delay()
  init_engine_init_delay_metro()
  Common.init(r_polls, r_params, ui, SETTINGS_FILE)
end

function init_engine_init_delay_metro() -- TODO: dim screen until done
  local engine_init_delay_metro = metro.init()
  engine_init_delay_metro.event = function()
    engine_ready = true

    Common.set_ui_dirty()

    engine_init_delay_metro:stop()
  end
  engine_init_delay_metro.time = 1
  engine_init_delay_metro:start()
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
