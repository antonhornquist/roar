-- common logic for unified, paged UI broken out to a shared file
--
-- assumptions:
--   1. norns globals (screen, params, %c) are defined
--   2. UI global is loaded with lib/ui.lua library
--   3. a page_params global is setup in the script that includes this file. it consists of a table of tables describing which params are on what page, and provides logic for formatting param values suitable for the enlarged, paged user interface
--
-- warning: including this file pollutes the global namespace with the following functions: redraw, enc, key, arc_delta, ui_update, ui_set_page, ui_get_page, ui_get_current_page_param_id

local HI_LEVEL = 15
local LO_LEVEL = 4
local FPS = 120

local fine = false
local prev_held = false
local next_held = false

local target_page
local current_page
local page_trans_frames
local page_trans_div

local num_pages
local transition_to_page

-- global functions

function redraw()
  local enc1_x = 0
  local enc1_y = 12

  local enc2_x = 10
  local enc2_y = 31 -- 33

  local enc3_x = enc2_x+65
  local enc3_y = enc2_y

  local key2_x = 0
  local key2_y = 63

  local key3_x = key2_x+65
  local key3_y = key2_y

  local function redraw_enc1_widget()
    screen.move(enc1_x, enc1_y)

    screen.level(LO_LEVEL)
    screen.text("LEVEL")
    screen.move(enc1_x+45, enc1_y)
    screen.level(HI_LEVEL)
    screen.text(util.round(mix:get_raw("output")*100, 1))
  end

  local function redraw_event_flash_widget()
    screen.level(LO_LEVEL)
    screen.rect(122, enc1_y-7, 5, 5)
    screen.fill()
  end

  local function draw_ui_param(page, param_index, x, y)
    local ui_param = page_params[page][param_index]
    screen.move(x, y)
    screen.level(LO_LEVEL)
    screen.text(ui_param.label)
    screen.move(x, y+12)
    screen.level(HI_LEVEL)
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
    local div = 128/num_pages()
    screen.level(LO_LEVEL)
    screen.rect(util.round((current_page-1)*div), enc2_y+15+1, util.round(div), 2)
    screen.fill()
  end

  local function redraw_key2key3_widget()
    screen.move(key2_x+(key3_x-key2_x)/2, key2_y)
    screen.level(HI_LEVEL)
    screen.text("FINE")
  end

  local function redraw_key2_widget()
    screen.move(key2_x, key2_y)
    if prev_held then
      screen.level(HI_LEVEL)
    else
      screen.level(LO_LEVEL)
    end
    screen.text("PREV")
  end

  local function redraw_key3_widget()
    screen.move(key3_x, key3_y)
    if next_held then
      screen.level(HI_LEVEL)
    else
      screen.level(LO_LEVEL)
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

  if fine then
    redraw_key2key3_widget()
  else
    redraw_key2_widget()
    redraw_key3_widget()
  end

  screen.update()
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
    params:delta(ui_get_current_page_param_id(n-1), d)
  end
end

function key(n, z)
  local page

  if target_page then
    page = target_page
  else
    page = ui_get_page()
  end

  if n == 2 then
    if z == 1 then
      page = page - 1
      if page < 1 then
        page = num_pages()
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
      if page > num_pages() then
        page = 1
      end

      transition_to_page(page)

      next_held = true
    else
      next_held = false
    end
    UI.set_dirty()
  end

  fine = prev_held and next_held
end

function arc_delta(n, delta)
  local d
  if fine then
    d = delta/5
  else
    d = delta
  end
  local id = ui_get_current_page_param_id(n)
  local val = params:get_raw(id)
  params:set_raw(id, val+d/500)
end

function ui_get_fps()
  return FPS
end

function ui_update()
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

function ui_set_page(page)
  current_page = page
end

function ui_get_page()
  return util.round(current_page)
end

function ui_get_current_page_param_id(n)
  local page = ui_get_page()
  return page_params[page][n].id
end

-- local functions

function num_pages()
  return #page_params
end

function transition_to_page(page)
  target_page = page
  page_trans_frames = FPS/5
  page_trans_div = (target_page - current_page) / page_trans_frames
end
