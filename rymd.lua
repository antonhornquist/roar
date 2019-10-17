-- scriptname: rymd
-- v1.1.0 @jah

engine.name = 'R'

local ControlSpec = require 'controlspec'
local Formatters = require 'formatters'
local R = require('r/lib/r') -- assumes r engine resides in ~/dust/code/r folder
local UI = include('lib/ui')

local fine = false -- TODO
local current_page = 1
local fps = 120

local function create_modules()
  engine.new("LFO", "MultiLFO")
  engine.new("SoundIn", "SoundIn")
  engine.new("Direct", "SGain")
  engine.new("FXSend", "SGain")
  engine.new("Delay1", "Delay")
  engine.new("Delay2", "Delay")
  engine.new("Filter1", "MMFilter")
  engine.new("Filter2", "MMFilter")
  engine.new("Feedback", "SGain")
  engine.new("SoundOut", "SoundOut")
end

local function set_static_module_params()
  engine.set("Filter1.Resonance", 0.1)
  engine.set("Filter2.Resonance", 0.1)
end

local function connect_modules()
  engine.connect("LFO/Sine", "Delay1/DelayTimeModulation")
  engine.connect("LFO/Sine", "Delay2/DelayTimeModulation")
  engine.connect("SoundIn/Left", "Direct/Left")
  engine.connect("SoundIn/Right", "Direct/Right")
  engine.connect("Direct/Left", "SoundOut/Left")
  engine.connect("Direct/Right", "SoundOut/Right")

  engine.connect("SoundIn/Left", "FXSend/Left")
  engine.connect("SoundIn/Right", "FXSend/Right")
  engine.connect("FXSend/Left", "Delay1/In")
  engine.connect("FXSend/Right", "Delay2/In")
  engine.connect("Delay1/Out", "Filter1/In")
  engine.connect("Delay2/Out", "Filter2/In")
  engine.connect("Filter1/Lowpass", "Feedback/Left")
  engine.connect("Filter2/Lowpass", "Feedback/Right")
  engine.connect("Feedback/Left", "Delay2/In")
  engine.connect("Feedback/Right", "Delay1/In")
  engine.connect("Filter1/Lowpass", "SoundOut/Left")
  engine.connect("Filter2/Lowpass", "SoundOut/Right")
end

local function init_params()
  params:add {
    type="control",
    id="direct",
    name="Direct",
    controlspec=R.specs.SGain.Gain,
    action=function (value)
      engine.set("Direct.Gain", value)
      UI.set_dirty()
    end
  }

  local delay_send_spec = R.specs.SGain.Gain
  delay_send_spec.default = -10

  params:add {
    type="control",
    id="delay_send",
    name="Delay Send",
    controlspec=delay_send_spec,
    action=function (value)
      engine.set("FXSend.Gain", value)
      UI.set_dirty()
    end
  }

  local delay_time_left_spec = R.specs.Delay.DelayTime
  delay_time_left_spec.default = 400

  params:add {
    type="control",
    id="delay_time_left",
    name="Delay Time Left",
    controlspec=delay_time_left_spec,
    action=function (value)
      engine.set("Delay1.DelayTime", value)
      UI.set_dirty()
    end
  }

  local delay_time_right_spec = R.specs.Delay.DelayTime
  delay_time_right_spec.default = 300

  params:add {
    type="control",
    id="delay_time_right",
    name="Delay Time Right",
    controlspec=delay_time_right_spec,
    action=function (value)
      engine.set("Delay2.DelayTime", value)
      UI.set_dirty()
    end
  }

  local filter_spec = R.specs.MMFilter.Frequency:copy()
  filter_spec.default = 4000
  filter_spec.maxval = 10000

  params:add {
    type="control",
    id="damping",
    name="Damping",
    controlspec=filter_spec,
    action=function(value)
      engine.set("Filter1.Frequency", value)
      engine.set("Filter2.Frequency", value)
      UI.set_dirty()
    end
  }

  local feedback_spec = R.specs.SGain.Gain:copy()
  feedback_spec.default = -10
  feedback_spec.maxval = 0

  params:add {
    type="control",
    id="feedback",
    name="Feedback",
    controlspec=feedback_spec,
    action=function (value)
      engine.set("Feedback.Gain", value)
      UI.set_dirty()
    end
  }

  params:add {
    type="control",
    id="mod_rate",
    name="Mod Rate",
    controlspec=R.specs.MultiLFO.Frequency,
    formatter=Formatters.round(0.001),
    action=function (value)
      engine.set("LFO.Frequency", value)
      UI.set_dirty()
    end
  }

  params:add {
    type="control",
    id="delay_time_mod_depth",
    name="Delay Time Mod Depth",
    controlspec=ControlSpec.UNIPOLAR,
    formatter=Formatters.percentage,
    action=function(value)
      engine.set("Delay1.DelayTimeModulation", value)
      engine.set("Delay2.DelayTimeModulation", value)
      UI.set_dirty()
    end
  }
end

local function refresh_ui()
  if target_page then
    current_page = current_page + page_trans_div
    page_trans_frames = page_trans_frames - 1
    if page_trans_frames == 0 then
      current_page = target_page
      target_page = nil
    end
    UI.set_dirty()
  end
  UI.refresh()
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
      if fine then
        d = delta/5
      else
        d = delta
      end
      change_current_page_param_raw_delta(n, d/500)
    end,
    on_refresh = function(my_arc)
      my_arc:all(0)
      my_arc:led(1, util.round(params:get_raw(get_current_page_param_id(1))*64), 15)
      my_arc:led(2, util.round(params:get_raw(get_current_page_param_id(2))*64), 15)
    end
  }

  UI.init_screen {
    on_refresh = function()
      redraw()
    end
  }

  init_ui_refresh_metro()
end

function init()
  create_modules()
  set_static_module_params()
  connect_modules()
  init_params()
  init_ui()

  params:read()
  params:bang()
end

function cleanup()
  params:write()
end

local function format_percentage(value)
  return util.round(value*100, 1) .. "%"
end

local function format_time(ms)
  if util.round(ms, 1) < 1000 then
    return util.round(ms, 1) .. "ms"
  elseif util.round(ms, 1) < 10000 then
    return util.round(ms/1000, 0.01) .. "s"
  else
    return util.round(ms/1000, 0.1) .. "s"
  end
end

local function format_freq(hz)
  if hz < 1 then
    local str = tostring(util.round(hz, 0.001))
    return string.sub(str, 2, #str).."Hz"
  elseif hz < 10 then
    return util.round(hz, 0.01).."Hz"
  elseif hz < 100 then
    return util.round(hz, 0.1).."Hz"
  elseif hz < 1000 then
    return util.round(hz, 1).."Hz"
  elseif hz < 10000 then
    return util.round(hz/1000, 0.1) .. "kHz"
  else
    return util.round(hz/1000, 1) .. "kHz"
  end
end

local ui_params = {
  {
    {
      label="DIR",
      id="direct",
      value=function(id)
        return params:get(id)
      end
    },
    {
      label="SEND",
      id="delay_send",
      value=function(id)
        return params:get(id)
      end
    }
  },
  {
    {
      label="L.TIME",
      id="delay_time_left",
      value=function(id)
        return format_time(params:get(id))
      end
    },
    {
      label="R.TIME",
      id="delay_time_right",
      value=function(id)
        return format_time(params:get(id))
      end
    }
  },
  {
    {
      label="DAMP",
      id="damping",
      value=function(id)
        return format_freq(params:get(id))
      end
    },
    {
      label="FBK",
      id="feedback",
      value=function(id)
        return params:get(id)
      end
    }
  },
  {
    {
      label="RATE",
      id="mod_rate",
      value=function(id)
        return format_freq(params:get(id))
      end
    },
    {
      label="MOD",
      id="delay_time_mod_depth",
      value=function(id)
        return format_percentage(params:get(id))
      end
    }
  },
}

local num_pages = #ui_params

function redraw()
  local hi_level = 15
  local lo_level = 4

  local enc1_x = 0
  local enc1_y = 12

  local enc2_x = 10
  local enc2_y = 33

  local enc3_x = enc2_x+65
  local enc3_y = enc2_y

  local key2_x = 0
  local key2_y = 63

  local key3_x = key2_x+65
  local key3_y = key2_y

  local function redraw_enc1_widget()
    screen.move(enc1_x, enc1_y)

    screen.level(lo_level)
    screen.text("LEVEL")
    screen.move(enc1_x+45, enc1_y)
    screen.level(hi_level)
    screen.text(util.round(mix:get_raw("output")*100, 1))
  end

  local function redraw_event_flash_widget()
    screen.level(lo_level)
    screen.rect(122, enc1_y-7, 5, 5)
    screen.fill()
  end

  local function draw_ui_param(page, param_index, x, y)
    local ui_param = ui_params[page][param_index]
    screen.move(x, y)
    screen.level(lo_level)
    screen.text(ui_param.label)
    screen.move(x, y+12)
    screen.level(hi_level)
    screen.text(ui_param.value(ui_param.id))
  end

  local function redraw_enc2_widget()
    local left = math.floor(current_page)
    local right = math.ceil(current_page)
    local offset = current_page - left
    local pixel_ofs = util.round(offset*128)

    draw_ui_param(left, 1, enc2_x-pixel_ofs, enc2_y)

    if left ~= right then
      draw_ui_param(right, 1, enc2_x+128-pixel_ofs, enc2_y)
    end
  end

  local function redraw_enc3_widget()
    local left = math.floor(current_page)
    local right = math.ceil(current_page)
    local offset = current_page - left
    local pixel_ofs = util.round(offset*128)

    draw_ui_param(left, 2, enc3_x-pixel_ofs, enc3_y)

    if left ~= right then
      draw_ui_param(right, 2, enc3_x+128-pixel_ofs, enc3_y)
    end
  end
    
  local function redraw_page_indicator()
    local div = 128/num_pages
    screen.level(lo_level)
    screen.rect(util.round((current_page-1)*div), enc2_y+15, util.round(div), 2)
    screen.fill()
  end

  local function redraw_key2_widget()
    screen.move(key2_x, key2_y)
    if prev_held then
      screen.level(hi_level)
    else
      screen.level(lo_level)
    end
    screen.text("PREV")
  end

  local function redraw_key3_widget()
    screen.move(key3_x, key3_y)
    if next_held then
      screen.level(hi_level)
    else
      screen.level(lo_level)
    end
    screen.text("NEXT")
  end

  screen.font_size(16)
  screen.clear()

  redraw_enc1_widget()

  if UI.show_event_indicator then
    redraw_event_flash_widget()
  end

  redraw_enc2_widget()
  redraw_enc3_widget()

  redraw_page_indicator()

  redraw_key2_widget()
  redraw_key3_widget()

  screen.update()
end

function get_current_page_param_id(n)
  local page = util.round(current_page)
  return ui_params[page][n].id
end

function transition_to_page(page)
  source_page = current_page
  target_page = page
  page_trans_frames = fps/5
  page_trans_div = (target_page - source_page) / page_trans_frames
end

function change_current_page_param_delta(n, delta)
  params:delta(get_current_page_param_id(n), delta)
end

function change_current_page_param_raw_delta(n, rawdelta)
  local id = get_current_page_param_id(n)
  local val = params:get_raw(id)
  params:set_raw(id, val+rawdelta)
end

function enc(n, delta)
  local d
  if fine then
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
  local page
  if target_page then
    page = target_page
  else
    page = util.round(current_page)
  end
  if n == 2 then
    if z == 1 then
      page = page - 1
      if page < 1 then
        page = num_pages
      end
      transition_to_page(page)

      prev_held = true
    else
      prev_held = false
    end
    UI.set_dirty()
  elseif n == 3 then
    if z == 1 then
      page = page + 1
      if page > num_pages then
        page = 1
      end
      transition_to_page(page)

      next_held = true
    else
      next_held = false
    end
    UI.set_dirty()
  end
end
