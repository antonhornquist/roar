-- scriptname: skev
-- v1.1.1 @jah

engine.name = 'R'

local Formatters = require('formatters')
local R = require('r/lib/r') -- assumes r engine resides in ~/dust/code/r folder
local UI = include('lib/ui')

local current_page = 1
local fps = 120

local function create_modules()
  engine.new("LFO", "MultiLFO")
  engine.new("SoundIn", "SoundIn")
  engine.new("PitchShift", "PShift")
  engine.new("FreqShift", "FShift")
  engine.new("SoundOut", "SoundOut")
end

local function connect_modules()
  engine.connect("LFO/Sine", "FreqShift/FM")
  engine.connect("LFO/Sine", "PitchShift/PitchRatioModulation")

  engine.connect("SoundIn/Left", "PitchShift/Left")
  engine.connect("SoundIn/Right", "PitchShift/Right")
  engine.connect("PitchShift/Left", "FreqShift/Left")
  engine.connect("PitchShift/Right", "FreqShift/Right")
  engine.connect("FreqShift/Left", "SoundOut/Left")
  engine.connect("FreqShift/Right", "SoundOut/Right")
end

local function init_params()
  params:add {
    type="control",
    id="pitch_ratio",
    name="Pitch Ratio",
    formatter=Formatters.percentage,
    controlspec=R.specs.PShift.PitchRatio,
    action=function (value)
      engine.set("PitchShift.PitchRatio", value)
      UI.set_dirty()
    end
  }

  params:add {
    type="control",
    id="freq_shift",
    name="Freq Shift",
    controlspec=R.specs.FShift.Frequency,
    action=function (value)
      engine.set("FreqShift.Frequency", value)
      UI.set_dirty()
    end
  }

  params:add {
    type="control",
    id="pitch_dispersion",
    name="Pitch Dispersion",
    formatter=Formatters.percentage,
    controlspec=R.specs.PShift.PitchDispersion,
    action=function (value)
      engine.set("PitchShift.PitchDispersion", value)
      UI.set_dirty()
    end
  }

  params:add {
    type="control",
    id="time_dispersion",
    name="Time Dispersion",
    formatter=Formatters.percentage,
    controlspec=R.specs.PShift.TimeDispersion,
    action=function (value)
      engine.set("PitchShift.TimeDispersion", value)
      UI.set_dirty()
    end
  }

  params:add {
    type="control",
    id="lfo_rate",
    name="LFO Rate",
    formatter=Formatters.round(0.001),
    controlspec=R.specs.MultiLFO.Frequency,
    action=function (value)
      engine.set("LFO.Frequency", value)
      UI.set_dirty()
    end
  }

  params:add {
    type="control",
    id="lfo_to_freq_shift",
    name="LFO > Freq Shift",
    formatter=Formatters.percentage,
    controlspec=R.specs.FShift.FM,
    action=function (value)
      engine.set("FreqShift.FM", value)
      UI.set_dirty()
    end
  }

  params:add {
    type="control",
    id="lfo_to_pitch_ratio",
    name="LFO > Pitch Ratio",
    formatter=Formatters.percentage,
    controlspec=R.specs.PShift.PitchRatioModulation,
    action=function (value)
      engine.set("PitchShift.PitchRatioModulation", value)
      UI.set_dirty()
    end
  }
end

--[[
local function init_ui_refresh_metro()
  local ui_refresh_metro = metro.init()
  ui_refresh_metro.event = UI.refresh
  ui_refresh_metro.time = 1/60
  ui_refresh_metro:start()
end

local function init_ui()
  UI.init_arc {
    device = arc.connect(),
    delta_callback = function(n, delta)
      local d
      if fine then
        d = delta/5
      else
        d = delta
      end
      if n == 1 then
        local val = params:get_raw("pitch_ratio")
        params:set_raw("pitch_ratio", val+d/500)
      elseif n == 2 then
        local val = params:get_raw("freq_shift")
        params:set_raw("freq_shift", val+d/500)
      end
      flash_event()
      UI.set_dirty()
    end,
    refresh_callback = function(my_arc)
      my_arc:all(0)
      my_arc:led(1, util.round(params:get_raw("pitch_ratio")*64), 15)
      my_arc:led(2, util.round(params:get_raw("freq_shift")*64), 15)
    end
  }

  UI.init_screen {
    refresh_callback = function()
      redraw()
    end
  }

  init_ui_refresh_metro()
end
]]

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
  connect_modules()
  init_params()
  init_ui()

  params:read()
  params:bang()
end

function cleanup()
  params:write()
end

local ui_params = {
  {
    {
      label="P.SHIFT",
      id="pitch_ratio",
      value=function(id)
        return params:string(id)
      end
    },
    {
      label="F.SHIFT",
      id="freq_shift",
      value=function(id)
        return params:string(id)
      end
    }
  },
  {
    {
      label="P.DISP",
      id="pitch_dispersion",
      value=function(id)
        return params:string(id)
      end
    },
    {
      label="T.DISP",
      id="time_dispersion",
      value=function(id)
        return params:string(id)
      end
    }
  },
  {
    {
      label="LFO.HZ",
      id="lfo_rate",
      value=function(id)
        return params:string(id)
      end
    },
    {
      label="L.SHP",
      id="lfo_rate",
      value=function(id)
        return params:string(id)
      end
    }
  },
  {
    {
      label=">P.RAT",
      id="lfo_to_pitch_ratio",
      value=function(id)
        return params:string(id)
      end
    },
    {
      label=">F.SHFT",
      id="lfo_to_freq_shift",
      value=function(id)
        return params:string(id)
      end
    }
  }
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
      --[[
      --TODO
      if page < 1 then
        current_page = num_pages
      else
        transition_to_page(page)
      end
      ]]
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
      --[[
      --TODO
      if page > num_pages then
        current_page = 1
      else
        transition_to_page(page)
      end
      ]]
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
