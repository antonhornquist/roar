-- scriptname: moln
-- v1.3.0 @jah

engine.name = 'R'

RMoln = include('lib/r_moln')
Formatters = include('lib/formatters')
Common = include('lib/common')

SETTINGS_FILE = "moln.data"
FPS = 35

engine_ready = false

function init()
  r_polls, visual_values, r_params = RMoln.init(util.round(FPS/20))

  ui = {
    arc = { device = arc.connect() },
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
          local note = gridkey_to_note(x, y, Common.get_grid_width())
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
        for voicenum=1,RMoln.POLYPHONY do
          local note = RMoln.note_downs[voicenum]
          if note then
            local x, y = note_to_gridkey(note, Common.get_grid_width())
            my_grid:led(x, y, 15)
          end
        end
      end
    },
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
          formatter=Formatters.adaptive_freq
        },
        {
          label="RES",
          id="filter_resonance",
          formatter=Formatters.percentage
        }
      },
      {
        {
          label="A.RNG",
          id="osc_a_range",
          formatter=Formatters.range
        },
        {
          label="B.RNG",
          id="osc_b_range",
          formatter=Formatters.range
        }
      },
      {
        {
          label="A.PW",
          id="osc_a_pulsewidth",
          formatter=Formatters.percentage
        },
        {
          label="B.PW",
          id="osc_b_pulsewidth",
          formatter=Formatters.percentage
        }
      },
      {
        {
          label="DETUN",
          id="osc_detune",
          formatter=Formatters.percentage
        },
        {
          label="LFO",
          id="lfo_frequency",
          formatter=Formatters.adaptive_freq
        },
      },
      {
        {
          label="PWM",
          id="lfo_to_osc_pwm",
          formatter=Formatters.percentage
        },
        {
          label="E>FIL",
          id="env_to_filter_fm",
          formatter=Formatters.percentage
        },
      },
      {
        {
          label="E.ATK",
          id="env_attack",
          formatter=Formatters.adaptive_time
        },
        {
          label="E.DEC",
          id="env_decay",
          formatter=Formatters.adaptive_time
        },
      },
      {
        {
          label="E.SUS",
          id="env_sustain",
          formatter=Formatters.percentage
        },
        {
          label="E.REL",
          id="env_release",
          formatter=Formatters.adaptive_time
        }
      }
    }
  }

  start_after_1_second_delay()
end

function start_after_1_second_delay()
  init_engine_init_delay_metro()
  Common.init(r_polls, r_params, ui, SETTINGS_FILE, FPS)
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
