-- assumes r engine is loaded and norns engine global available

local R = require('r/lib/r') -- assumes r engine resides in ~/dust/code/r folder
local ControlSpec = require('controlspec')
local Formatters = require('formatters')
local CappedList = include('lib/capped_list')
local Voice = require('voice')

local Module = {}

local init_r_modules
local init_r_params

local POLYPHONY = 5
local note_downs = {}
local note_slots = {}
local voice_allocator

Module.POLYPHONY = POLYPHONY
Module.note_downs = note_downs

function Module.init(visual_buf_size)
  voice_allocator = Voice.new(POLYPHONY)

  init_r_modules()
  local r_params = init_r_params()
  return {}, {}, r_params
end

local create_modules
local set_static_module_params
local connect_modules
local create_macros

function init_r_modules()
  create_modules()
  set_static_module_params()
  connect_modules()
  create_macros()
end

function create_modules()
  R.engine.poly_new("FreqGate", "FreqGate", POLYPHONY)
  R.engine.poly_new("LFO", "SineLFO", POLYPHONY)
  R.engine.poly_new("Env", "ADSREnv", POLYPHONY)
  R.engine.poly_new("OscA", "PulseOsc", POLYPHONY)
  R.engine.poly_new("OscB", "PulseOsc", POLYPHONY)
  R.engine.poly_new("Filter", "LPFilter", POLYPHONY)
  R.engine.poly_new("Amp", "Amp", POLYPHONY)

  engine.new("SoundOut", "SoundOut")
end

function set_static_module_params()
  R.engine.poly_set("OscA.FM", 1, POLYPHONY)
  R.engine.poly_set("OscB.FM", 1, POLYPHONY)
  R.engine.poly_set("Filter.AudioLevel", 1, POLYPHONY)
end

function connect_modules()
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

function create_macros()
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

function init_r_params()
  local r_params = {}

  local filter_frequency_spec = R.specs.LPFilter.Frequency:copy()
  filter_frequency_spec.maxval = 8000
  filter_frequency_spec.minval = 10
  filter_frequency_spec.default = 500

  table.insert(r_params, {
    id="filter_frequency",
    name="Filter Frequency",
    controlspec=filter_frequency_spec,
    action=function (value)
      engine.macroset("filter_frequency", value)
    end
  })

  local filter_resonance_spec = R.specs.LPFilter.Resonance:copy()
  filter_resonance_spec.default = 0.2

  table.insert(r_params, {
    id="filter_resonance",
    name="Filter Resonance",
    controlspec=filter_resonance_spec,
    formatter=Formatters.percentage,
    action=function (value)
      engine.macroset("filter_resonance", value)
    end
  })

  table.insert(r_params, {
    id="osc_a_range",
    name="Osc A Range",
    controlspec=R.specs.PulseOsc.Range,
    formatter=Formatters.round(1),
    action=function (value)
      engine.macroset("osc_a_range", value)
    end
  })

  table.insert(r_params, {
    id="osc_b_range",
    name="Osc B Range",
    controlspec=R.specs.PulseOsc.Range,
    formatter=Formatters.round(1),
    action=function (value)
      engine.macroset("osc_b_range", value)
    end
  })

  local osc_a_pulsewidth_spec = R.specs.PulseOsc.PulseWidth:copy()
  osc_a_pulsewidth_spec.default = 0.88

  table.insert(r_params, {
    id="osc_a_pulsewidth",
    name="Osc A PulseWidth",
    controlspec=osc_a_pulsewidth_spec,
    formatter=Formatters.percentage,
    action=function (value)
      engine.macroset("osc_a_pulsewidth", value)
    end
  })

  local osc_b_pulsewidth_spec = R.specs.PulseOsc.PulseWidth:copy()
  osc_b_pulsewidth_spec.default = 0.61

  table.insert(r_params, {
    id="osc_b_pulsewidth",
    name="Osc B PulseWidth",
    controlspec=osc_b_pulsewidth_spec,
    formatter=Formatters.percentage,
    action=function (value)
      engine.macroset("osc_b_pulsewidth", value)
    end
  })

  local osc_detune_spec = ControlSpec.UNIPOLAR:copy()
  osc_detune_spec.default = 0.36

  table.insert(r_params, {
    id="osc_detune",
    name="Detune",
    controlspec=osc_detune_spec,
    formatter=Formatters.percentage,
    action=function (value)
      engine.macroset("osc_a_detune", -value*20)
      engine.macroset("osc_b_detune", value*20)
    end
  })

  local lfo_frequency_spec = R.specs.MultiLFO.Frequency:copy()
  lfo_frequency_spec.default = 0.125

  table.insert(r_params, {
    id="lfo_frequency",
    name="PWM Rate",
    controlspec=lfo_frequency_spec,
    formatter=Formatters.round(0.001),
    action=function (value)
      engine.macroset("lfo_frequency", value)
    end
  })

  local lfo_to_osc_pwm_spec = ControlSpec.UNIPOLAR:copy()
  lfo_to_osc_pwm_spec.default = 0.46

  table.insert(r_params, {
    id="lfo_to_osc_pwm",
    name="PWM Depth",
    controlspec=lfo_to_osc_pwm_spec,
    formatter=Formatters.percentage,
    action=function (value)
      engine.macroset("osc_a_pwm", value*0.76)
      engine.macroset("osc_b_pwm", value*0.56)
    end
  })

  local env_to_filter_fm_spec = R.specs.LPFilter.FM
  env_to_filter_fm_spec.default = 0.35

  table.insert(r_params, {
    id="env_to_filter_fm",
    name="Env > Filter Frequency",
    controlspec=env_to_filter_fm_spec,
    formatter=Formatters.percentage,
    action=function (value)
      engine.macroset("env_to_filter_fm", value)
    end
  })

  local env_attack_spec = R.specs.ADSREnv.Attack:copy()
  env_attack_spec.default = 1

  table.insert(r_params, {
    id="env_attack",
    name="Env Attack",
    controlspec=env_attack_spec,
    action=function (value)
      engine.macroset("env_attack", value)
    end
  })

  local env_decay_spec = R.specs.ADSREnv.Decay:copy()
  env_decay_spec.default = 200

  table.insert(r_params, {
    id="env_decay",
    name="Env Decay",
    controlspec=env_decay_spec,
    action=function (value)
      engine.macroset("env_decay", value)
    end
  })

  local env_sustain_spec = R.specs.ADSREnv.Sustain:copy()
  env_sustain_spec.default = 0.5

  table.insert(r_params, {
    id="env_sustain",
    name="Env Sustain",
    controlspec=env_sustain_spec,
    formatter=Formatters.percentage,
    action=function (value)
      engine.macroset("env_sustain", value)
    end
  })

  local env_release_spec = R.specs.ADSREnv.Release:copy()
  env_release_spec.default = 500

  table.insert(r_params, {
    id="env_release",
    name="Env Release",
    controlspec=env_release_spec,
    action=function (value)
      engine.macroset("env_release", value)
    end
  })

  for _,r_param in ipairs(r_params) do
    r_param.type = "control"
  end

  return r_params
end

local trig_voice
local release_voice

function Module.note_on(note, velocity)
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
  end
end

local to_hz

function trig_voice(voicenum, note)
  engine.bulkset("FreqGate"..voicenum..".Gate 1 FreqGate"..voicenum..".Frequency "..to_hz(note))
end

function to_hz(note)
  local exp = (note - 21) / 12
  return 27.5 * 2^exp
end

function release_voice(voicenum)
  engine.bulkset("FreqGate"..voicenum..".Gate 0")
end

function Module.note_off(note)
  local slot = note_slots[note]
  if slot then
    voice_allocator:release(slot)
    note_downs[slot.id] = nil
  end
end

return Module
