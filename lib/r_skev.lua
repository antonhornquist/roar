-- TODO: uses engine global (could be passed in init())
-- TODO: assumes R engine is loaded (or should this be done here?)

local R = require('r/lib/r') -- assumes r engine resides in ~/dust/code/r folder
local ControlSpec = require('controlspec') -- TODO
local Formatters = require('formatters')
local CappedList = include('lib/capped_list')

local Module = {}

local init_r
local init_visual_values_bufs
local init_r_params
local init_r_polls

function Module.init(visual_buf_size)
  init_r()
  init_visual_values_bufs(visual_buf_size)
  local r_polls = init_r_polls()
  local r_params = init_r_params()
  return r_polls, r_params
end

local create_modules
local connect_modules

function init_r()
  create_modules()
  connect_modules()
  engine.pollvisual(0, "FreqShift.Frequency") -- TODO: should be indexed from 1
  engine.pollvisual(1, "PitchShift.PitchRatio") -- TODO: should be indexed from 1
end

function create_modules()
  engine.new("LFO", "MultiLFO")
  engine.new("SoundIn", "SoundIn")
  engine.new("PitchShift", "PShift")
  engine.new("FreqShift", "FShift")
  engine.new("SoundOut", "SoundOut")
end

function connect_modules()
  engine.connect("LFO/Sine", "FreqShift/FM")
  engine.connect("LFO/Sine", "PitchShift/PitchRatioModulation")

  engine.connect("SoundIn/Left", "PitchShift/Left")
  engine.connect("SoundIn/Right", "PitchShift/Right")
  engine.connect("PitchShift/Left", "FreqShift/Left")
  engine.connect("PitchShift/Right", "FreqShift/Right")
  engine.connect("FreqShift/Left", "SoundOut/Left")
  engine.connect("FreqShift/Right", "SoundOut/Right")
end

function init_visual_values_bufs(visual_buf_size)
  Module.visual_values = {
    delay_time_left = CappedList.create(visual_buf_size)
    delay_time_right = CappedList.create(visual_buf_size)
  }
end

local delay_time_left_spec
local delay_time_right_spec

function init_r_polls()
  return {
    {
      id = "freq_shift",
      handler = function(value)
        local visual_value = R.specs.FShift.Frequency:unmap(value) -- TODO: establish visual specs in lua module
        Common.push_to_capped_list(freq_shift_visual_values, visual_value)
      end
    },
    {
      id = "pitch_ratio",
      handler = function(value)
        local visual_value = R.specs.PShift.PitchRatio:unmap(value) -- TODO: establish visual specs in lua module
        Common.push_to_capped_list(pitch_ratio_visual_values, visual_value)
      end
    }
  }
end

function init_r_params()
  local r_params = {}

  table.insert(r_params, {
    id="freq_shift",
    name="Freq Shift",
    controlspec=R.specs.FShift.Frequency,
    action=function (value)
      engine.set("FreqShift.Frequency", value)
    end
  })

  table.insert(r_params, {
    id="pitch_ratio",
    name="Pitch Ratio",
    formatter=Formatters.percentage,
    controlspec=R.specs.PShift.PitchRatio,
    action=function (value)
      engine.set("PitchShift.PitchRatio", value)
    end
  })

  table.insert(r_params, {
    id="pitch_dispersion",
    name="Pitch Dispersion",
    formatter=Formatters.percentage,
    controlspec=R.specs.PShift.PitchDispersion,
    action=function (value)
      engine.set("PitchShift.PitchDispersion", value)
    end
  })

  table.insert(r_params, {
    id="time_dispersion",
    name="Time Dispersion",
    formatter=Formatters.percentage,
    controlspec=R.specs.PShift.TimeDispersion,
    action=function (value)
      engine.set("PitchShift.TimeDispersion", value)
    end
  })

  table.insert(r_params, {
    id="lfo_rate",
    name="LFO Rate",
    formatter=Formatters.round(0.001),
    controlspec=R.specs.MultiLFO.Frequency,
    action=function (value)
      engine.set("LFO.Frequency", value)
      Common.set_ui_dirty()
    end
  })

  table.insert(r_params, {
    id="lfo_to_freq_shift",
    name="LFO > Freq Shift",
    formatter=Formatters.percentage,
    controlspec=R.specs.FShift.FM,
    action=function (value)
      engine.set("FreqShift.FM", value)
      Common.set_ui_dirty()
    end
  })

  table.insert(r_params, {
    id="lfo_to_pitch_ratio",
    name="LFO > Pitch Ratio",
    formatter=Formatters.percentage,
    controlspec=R.specs.PShift.PitchRatioModulation,
    action=function (value)
      engine.set("PitchShift.PitchRatioModulation", value)
      Common.set_ui_dirty()
    end
  })

  for _,r_param in ipairs(r_params) do
    r_param.type = "control"
  end

  return r_params
end

return Module
