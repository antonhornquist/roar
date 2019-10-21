-- scriptname: moln
-- v1.2.0 @jah

engine.name = 'R'

local ControlSpec = require('controlspec')
local Formatters = require('formatters')
local Voice = require('voice')
local R = require('r/lib/r') -- assumes r engine resides in ~/dust/code/r folder

local UI = include('lib/ui')
local Pages = include('lib/pages')
local RoarFormatters = include('lib/formatters')

local pages_state

local POLYPHONY = 5
local note_downs = {}
local note_slots = {}

local engine_ready = false
local fps = 120

local function create_modules()
  R.engine.poly_new("FreqGate", "FreqGate", POLYPHONY)
  R.engine.poly_new("LFO", "SineLFO", POLYPHONY)
  R.engine.poly_new("Env", "ADSREnv", POLYPHONY)
  R.engine.poly_new("OscA", "PulseOsc", POLYPHONY)
  R.engine.poly_new("OscB", "PulseOsc", POLYPHONY)
  R.engine.poly_new("Filter", "LPFilter", POLYPHONY)
  R.engine.poly_new("Amp", "Amp", POLYPHONY)

  engine.new("SoundOut", "SoundOut")
end

local function set_static_module_params()
  R.engine.poly_set("OscA.FM", 1, POLYPHONY)
  R.engine.poly_set("OscB.FM", 1, POLYPHONY)
  R.engine.poly_set("Filter.AudioLevel", 1, POLYPHONY)
end

local function connect_modules()
  R.engine.poly_connect("FreqGate/Frequency", "OscA/FM", POLYPHONY)
  R.engine.poly_connect("FreqGate/Frequency", "OscB/FM", POLYPHONY)
  R.engine.poly_connect("FreqGate/Gate", "Env/Gate", POLYPHONY)
  R.engine.poly_connect("LFO/Out", "OscA/PWM", POLYPHONY)
  R.engine.poly_connect("LFO/Out", "OscB/PWM", POLYPHONY)
  R.engine.poly_connect("Env/Out", "Amp/Lin", POLYPHONY)
  R.engine.poly_connect("Env/Out", "Filter/FM", POLYPHONY)
  R.engine.poly_connect("OscA/Out", "Filter/In", POLYPHONY)
  R.engine.poly_connect("OscB/Out", "Filter/In", POLYPHONY)
  R.engine.poly_connect("Filter/Out", "Amp/In", POLYPHONY)

  for voicenum=1, POLYPHONY do
    engine.connect("Amp"..voicenum.."/Out", "SoundOut/Left")
    engine.connect("Amp"..voicenum.."/Out", "SoundOut/Right")
  end
end

local function create_macros()
  engine.newmacro("osc_a_range", R.util.poly_expand("OscA.Range", POLYPHONY))
  engine.newmacro("osc_a_pulsewidth", R.util.poly_expand("OscA.PulseWidth", POLYPHONY))
  engine.newmacro("osc_b_range", R.util.poly_expand("OscB.Range", POLYPHONY))
  engine.newmacro("osc_b_pulsewidth", R.util.poly_expand("OscB.PulseWidth", POLYPHONY))
  engine.newmacro("osc_a_detune", R.util.poly_expand("OscA.Tune", POLYPHONY))
  engine.newmacro("osc_b_detune", R.util.poly_expand("OscB.Tune", POLYPHONY))
  engine.newmacro("lfo_frequency", R.util.poly_expand("LFO.Frequency", POLYPHONY))
  engine.newmacro("osc_a_pwm", R.util.poly_expand("OscA.PWM", POLYPHONY))
  engine.newmacro("osc_b_pwm", R.util.poly_expand("OscB.PWM", POLYPHONY))
  engine.newmacro("filter_frequency", R.util.poly_expand("Filter.Frequency", POLYPHONY))
  engine.newmacro("filter_resonance", R.util.poly_expand("Filter.Resonance", POLYPHONY))
  engine.newmacro("env_to_filter_fm", R.util.poly_expand("Filter.FM", POLYPHONY))
  engine.newmacro("env_attack", R.util.poly_expand("Env.Attack", POLYPHONY))
  engine.newmacro("env_decay", R.util.poly_expand("Env.Decay", POLYPHONY))
  engine.newmacro("env_sustain", R.util.poly_expand("Env.Sustain", POLYPHONY))
  engine.newmacro("env_release", R.util.poly_expand("Env.Release", POLYPHONY))
end

local function init_params()
  params:add {
    type="control",
    id="osc_a_range",
    name="Osc A Range",
    controlspec=R.specs.PulseOsc.Range,
    formatter=Formatters.round(1),
    action=function (value)
      engine.macroset("osc_a_range", value)
      UI.set_dirty()
    end
  }

  local osc_a_pulsewidth_spec = R.specs.PulseOsc.PulseWidth:copy()
  osc_a_pulsewidth_spec.default = 0.88

  params:add {
    type="control",
    id="osc_a_pulsewidth",
    name="Osc A PulseWidth",
    controlspec=osc_a_pulsewidth_spec,
    formatter=Formatters.percentage,
    action=function (value)
      engine.macroset("osc_a_pulsewidth", value)
      UI.set_dirty()
    end
  }

  params:add {
    type="control",
    id="osc_b_range",
    name="Osc B Range",
    controlspec=R.specs.PulseOsc.Range,
    formatter=Formatters.round(1),
    action=function (value)
      engine.macroset("osc_b_range", value)
      UI.set_dirty()
    end
  }

  local osc_b_pulsewidth_spec = R.specs.PulseOsc.PulseWidth:copy()
  osc_b_pulsewidth_spec.default = 0.61

  params:add {
    type="control",
    id="osc_b_pulsewidth",
    name="Osc B PulseWidth",
    controlspec=osc_b_pulsewidth_spec,
    formatter=Formatters.percentage,
    action=function (value)
      engine.macroset("osc_b_pulsewidth", value)
      UI.set_dirty()
    end
  }

  local osc_detune_spec = ControlSpec.UNIPOLAR:copy()
  osc_detune_spec.default = 0.36

  params:add {
    type="control",
    id="osc_detune",
    name="Detune",
    controlspec=osc_detune_spec,
    formatter=Formatters.percentage,
    action=function (value)
      engine.macroset("osc_a_detune", -value*20)
      engine.macroset("osc_b_detune", value*20)
      UI.set_dirty()
    end
  }

  local lfo_frequency_spec = R.specs.MultiLFO.Frequency:copy()
  lfo_frequency_spec.default = 0.125

  params:add {
    type="control",
    id="lfo_frequency",
    name="PWM Rate",
    controlspec=lfo_frequency_spec,
    formatter=Formatters.round(0.001),
    action=function (value)
      engine.macroset("lfo_frequency", value)
      UI.set_dirty()
    end
  }

  local lfo_to_osc_pwm_spec = ControlSpec.UNIPOLAR:copy()
  lfo_to_osc_pwm_spec.default = 0.46

  params:add {
    type="control",
    id="lfo_to_osc_pwm",
    name="PWM Depth",
    controlspec=lfo_to_osc_pwm_spec,
    formatter=Formatters.percentage,
    action=function (value)
      engine.macroset("osc_a_pwm", value*0.76)
      engine.macroset("osc_b_pwm", value*0.56)
      UI.set_dirty()
    end
  }

  local filter_frequency_spec = R.specs.LPFilter.Frequency:copy()
  filter_frequency_spec.maxval = 8000
  filter_frequency_spec.minval = 10
  filter_frequency_spec.default = 500

  params:add {
    type="control",
    id="filter_frequency",
    name="Filter Frequency",
    controlspec=filter_frequency_spec,
    action=function (value)
      engine.macroset("filter_frequency", value)
      UI.set_dirty()
    end
  }

  local filter_resonance_spec = R.specs.LPFilter.Resonance:copy()
  filter_resonance_spec.default = 0.2

  params:add {
    type="control",
    id="filter_resonance",
    name="Filter Resonance",
    controlspec=filter_resonance_spec,
    formatter=Formatters.percentage,
    action=function (value)
      engine.macroset("filter_resonance", value)
      UI.set_dirty()
    end
  }

  local env_to_filter_fm_spec = R.specs.LPFilter.FM
  env_to_filter_fm_spec.default = 0.35

  params:add {
    type="control",
    id="env_to_filter_fm",
    name="Env > Filter Frequency",
    controlspec=env_to_filter_fm_spec,
    formatter=Formatters.percentage,
    action=function (value)
      engine.macroset("env_to_filter_fm", value)
      UI.set_dirty()
    end
  }

  local env_attack_spec = R.specs.ADSREnv.Attack:copy()
  env_attack_spec.default = 1

  params:add {
    type="control",
    id="env_attack",
    name="Env Attack",
    controlspec=env_attack_spec,
    action=function (value)
      engine.macroset("env_attack", value)
      UI.set_dirty()
    end
  }

  local env_decay_spec = R.specs.ADSREnv.Decay:copy()
  env_decay_spec.default = 200

  params:add {
    type="control",
    id="env_decay",
    name="Env Decay",
    controlspec=env_decay_spec,
    action=function (value)
      engine.macroset("env_decay", value)
      UI.set_dirty()
    end
  }

  local env_sustain_spec = R.specs.ADSREnv.Sustain:copy()
  env_sustain_spec.default = 0.5

  params:add {
    type="control",
    id="env_sustain",
    name="Env Sustain",
    controlspec=env_sustain_spec,
    formatter=Formatters.percentage,
    action=function (value)
      engine.macroset("env_sustain", value)
      UI.set_dirty()
    end
  }

  local env_release_spec = R.specs.ADSREnv.Release:copy()
  env_release_spec.default = 500

  params:add {
    type="control",
    id="env_release",
    name="Env Release",
    controlspec=env_release_spec,
    action=function (value)
      engine.macroset("env_release", value)
      UI.set_dirty()
    end
  }

  params:add_separator()

  params:add {
    type="number",
    id="page",
    name="Page",
    default=1
  }
end

local function release_voice(voicenum)
  engine.bulkset("FreqGate"..voicenum..".Gate 0")
end

local function to_hz(note)
  local exp = (note - 21) / 12
  return 27.5 * 2^exp
end

local function note_on(note, velocity)
  local function trig_voice(voicenum, note)
    engine.bulkset("FreqGate"..voicenum..".Gate 1 FreqGate"..voicenum..".Frequency "..to_hz(note))
  end

  if not note_slots[note] then
    local slot = voice_allocator:get()
    local voicenum = slot.id
    trig_voice(voicenum, note)
    slot.on_release = function()
      release_voice(voicenum)
      note_slots[note] = nil
    end
    note_slots[note] = slot
    note_downs[voicenum] = note
    UI.screen_dirty = true
  end
end

local function note_off(note)
  local slot = note_slots[note]
  if slot then
    voice_allocator:release(slot)
    note_downs[slot.id] = nil
    UI.screen_dirty = true
  end
end

local function gridkey_to_note(x, y, grid_width)
  if grid_width == 16 then
    return x * 8 + y
  else
    return (4+x) * 8 + y
  end
end

local function note_to_gridkey(note, grid_width)
  if grid_width == 16 then
    return math.floor(note/8), note % 8
  else
    return math.floor(note/8) - 4, note % 8
  end
end

local function init_engine_init_delay_metro() -- TODO: dim screen until done
  local engine_init_delay_metro = metro.init()
  engine_init_delay_metro.event = function()
    engine_ready = true

    UI.set_dirty()

    engine_init_delay_metro:stop()
  end
  engine_init_delay_metro.time = 1
  engine_init_delay_metro:start()
end

local function refresh_ui()
  if Pages.refresh(pages_state, params) then
    UI.set_dirty()
  end
  UI.refresh()
end

local function init_pages()
  local ui_params = {
    {
      {
        label="FREQ",
        id="filter_frequency",
        value=function(id)
          return RoarFormatters.adaptive_freq(params:get(id))
        end
      },
      {
        label="RES",
        id="filter_resonance",
        value=function(id)
          return RoarFormatters.percentage(params:get(id))
        end
      }
    },
    {
      {
        label="A.RNG",
        id="osc_a_range",
        value=function(id)
          return RoarFormatters.range(params:get(id))
        end
      },
      {
        label="B.RNG",
        id="osc_b_range",
        value=function(id)
          return RoarFormatters.range(params:get(id))
        end
      }
    },
    {
      {
        label="A.PW",
        id="osc_a_pulsewidth",
        value=function(id)
          return RoarFormatters.percentage(params:get(id))
        end
      },
      {
        label="B.PW",
        id="osc_b_pulsewidth",
        value=function(id)
          return RoarFormatters.percentage(params:get(id))
        end
      }
    },
    {
      {
        label="DETUN",
        id="osc_detune",
        value=function(id)
          return RoarFormatters.percentage(params:get(id))
        end
      },
      {
        label="LFO",
        id="lfo_frequency",
        value=function(id)
          return RoarFormatters.adaptive_freq(params:get(id))
        end
      },
    },
    {
      {
        label="PWM",
        id="lfo_to_osc_pwm",
        value=function(id)
          return RoarFormatters.percentage(params:get(id))
        end
      },
      {
        label="E>FIL",
        id="env_to_filter_fm",
        value=function(id)
          return RoarFormatters.percentage(params:get(id))
        end
      },
    },
    {
      {
        label="E.ATK",
        id="env_attack",
        value=function(id)
          return RoarFormatters.adaptive_time(params:get(id))
        end
      },
      {
        label="E.DEC",
        id="env_decay",
        value=function(id)
          return RoarFormatters.adaptive_time(params:get(id))
        end
      },
    },
    {
      {
        label="E.SUS",
        id="env_sustain",
        value=function(id)
          return RoarFormatters.percentage(params:get(id))
        end
      },
      {
        label="E.REL",
        id="env_release",
        value=function(id)
          return RoarFormatters.adaptive_time(params:get(id))
        end
      }
    }
  }

  pages_state = Pages.init(ui_params, fps, params:get("page"))
end

local function init_ui_refresh_metro()
  local ui_refresh_metro = metro.init()
  ui_refresh_metro.event = refresh_ui
  ui_refresh_metro.time = 1/fps
  ui_refresh_metro:start()
end

local function init_ui()
  UI.init_arc {
    device = arc.connect(),
    on_delta = function(n, delta)
      local d
      if pages_state.fine then
        d = delta/5
      else
        d = delta
      end
      change_current_page_param_raw_delta(n, d/500)
    end,
    on_refresh = function(my_arc)
      my_arc:all(0)
      my_arc:led(1, util.round(params:get_raw(Pages.get_current_page_param_id(pages_state, 1))*64), 15)
      my_arc:led(2, util.round(params:get_raw(Pages.get_current_page_param_id(pages_state, 2))*64), 15)
    end
  }

  UI.init_grid {
    device = grid.connect(),
    on_key = function(x, y, state)
      if engine_ready then
        local note = gridkey_to_note(x, y, UI.grid_width)
        if state == 1 then
          note_on(note, 5)
        else
          note_off(note)
        end

        UI.grid_dirty = true
        UI.screen_dirty = true
      end
    end,
    on_refresh = function(my_grid)
      my_grid:all(0)
      for voicenum=1,POLYPHONY do
        local note = note_downs[voicenum]
        if note then
          local x, y = note_to_gridkey(note, UI.grid_width)
          my_grid:led(x, y, 15)
        end
      end
    end
  }

  UI.init_midi {
    device = midi.connect(),
    on_event = function (data)
      if engine_ready then
        if #data == 0 then return end
        local msg = midi.to_msg(data)
        if msg.type == "note_off" then
          note_off(msg.note)
        elseif msg.type == "note_on" then
          note_on(msg.note, msg.vel / 127)
        end
        UI.screen_dirty = true
      end
    end
  }

  UI.init_screen {
    on_refresh = function()
      redraw()
    end
  }

  init_ui_refresh_metro()
  init_engine_init_delay_metro()
end

function init()
  voice_allocator = Voice.new(POLYPHONY)

  create_modules()
  set_static_module_params()
  connect_modules()
  create_macros()

  init_params()

  params:read()
  params:bang()

  init_ui()
  init_pages()
end

function cleanup()
  params:write()
end

function redraw()
  Pages.redraw(pages_state, screen, UI.show_event_indicator)
end

function change_current_page_param_delta(n, delta)
  params:delta(Pages.get_current_page_param_id(pages_state, n), delta)
end

function change_current_page_param_raw_delta(n, rawdelta)
  local id = Pages.get_current_page_param_id(pages_state, n)
  local val = params:get_raw(id)
  params:set_raw(id, val+rawdelta)
end

function enc(n, delta)
  local d
  if pages_state.fine then
    d = delta/5
  else
    d = delta
  end
  if n == 1 then
    mix:delta("output", d)
    UI.screen_dirty = true
  else
    change_current_page_param_delta(n-1, d)
  end
end

function key(n, z)
  if n ~= 1 then
    Pages.nav(pages_state, n == 3, z)
    UI.set_dirty()
  end
end
