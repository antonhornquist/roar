-- utility library for paging UI
--
-- main entry points:
-- Pages.init

local hi_level = 15
local lo_level = 4

local current_page = 1
local target_page

local page_trans_frames
local page_trans_div

local num_pages

local Pages = {}

function Pages.init(ui_params, fps)
  Pages.ui_params = ui_params
  num_pages = #ui_params
  Pages.fps = fps

  print("Pages.init")
  print("num_pages: "..num_pages)
  print("fps: "..fps)
end

function Pages.refresh(UI)
  if target_page then
    current_page = current_page + page_trans_div
    page_trans_frames = page_trans_frames - 1
    if page_trans_frames == 0 then
      current_page = target_page
      target_page = nil
    end
    UI.set_dirty()
  end
end

function Pages.get_current_page_param_id(n)
  local page = util.round(current_page)
  return Pages.ui_params[page][n].id
end

function Pages.transition_to_page(page)
  source_page = current_page
  target_page = page
  page_trans_frames = Pages.fps/5
  page_trans_div = (target_page - source_page) / page_trans_frames
end

function Pages.key(n, z, UI)
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
      Pages.transition_to_page(page)

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
      Pages.transition_to_page(page)

      next_held = true
    else
      next_held = false
    end
    UI.set_dirty()
  end
end

function Pages.redraw(screen, UI)
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
    local ui_param = Pages.ui_params[page][param_index]
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

return Pages
