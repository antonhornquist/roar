-- utility library for paging UI
--
-- main entry points:
-- Pages.init

local HI_LEVEL = 15
local LO_LEVEL = 4

local Pages = {}

function Pages.init(ui_params, fps, init_page)
  return {
    ui_params = ui_params,
    num_pages = #ui_params,
    fps = fps,
    current_page = init_page,
    prev_held = false,
    next_held = false,
    fine = false,
    target_page = nil, -- TODO
    source_page = nil, -- TODO, not sure this needs to be stored in state table
    page_trans_frames = nil, -- TODO
    page_trans_div = nil -- TODO
  }
end

function Pages.refresh(state, UI, pset)
  if state.target_page then
    state.current_page = state.current_page + state.page_trans_div
    state.page_trans_frames = state.page_trans_frames - 1
    if state.page_trans_frames == 0 then
      state.current_page = state.target_page
      state.target_page = nil
    end
    pset:set("page", util.round(state.current_page))
    UI.set_dirty()
  end
end

function Pages.get_current_page_param_id(state, n)
  local page = util.round(state.current_page)
  return state.ui_params[page][n].id
end

function Pages.transition_to_page(state, page)
  state.source_page = state.current_page
  state.target_page = page
  state.page_trans_frames = state.fps/5
  state.page_trans_div = (state.target_page - state.source_page) / state.page_trans_frames
end

function Pages.key(state, n, z, UI)
  local page

  if state.target_page then
    page = state.target_page
  else
    page = util.round(state.current_page)
  end

  if n == 2 then
    if z == 1 then
      page = page - 1
      if page < 1 then
        page = state.num_pages
      end

      Pages.transition_to_page(page)

      state.prev_held = true
    else
      state.prev_held = false
    end
  elseif n == 3 then
    if z == 1 then
      page = page + 1
      if page > state.num_pages then
        page = 1
      end

      Pages.transition_to_page(page)

      state.next_held = true
    else
      state.next_held = false
    end
  end

  state.fine = state.prev_held and state.next_held

  UI.set_dirty()
end

function Pages.redraw(state, screen, UI)
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
    local ui_param = state.ui_params[page][param_index]
    screen.move(x, y)
    screen.level(LO_LEVEL)
    screen.text(ui_param.label)
    screen.move(x, y+12)
    screen.level(HI_LEVEL)
    screen.text(ui_param.value(ui_param.id))
  end

  local function redraw_enc2_widget()
    local left = math.floor(state.current_page)
    local right = math.ceil(state.current_page)
    local offset = state.current_page - left
    local pixel_ofs = util.round(offset*128)

    draw_ui_param(left, 1, enc2_x-pixel_ofs, enc2_y)

    if left ~= right then
      draw_ui_param(right, 1, enc2_x+128-pixel_ofs, enc2_y)
    end
  end

  local function redraw_enc3_widget()
    local left = math.floor(state.current_page)
    local right = math.ceil(state.current_page)
    local offset = state.current_page - left
    local pixel_ofs = util.round(offset*128)

    draw_ui_param(left, 2, enc3_x-pixel_ofs, enc3_y)

    if left ~= right then
      draw_ui_param(right, 2, enc3_x+128-pixel_ofs, enc3_y)
    end
  end
    
  local function redraw_page_indicator()
    local div = 128/state.num_pages
    screen.level(LO_LEVEL)
    screen.rect(util.round((state.current_page-1)*div), enc2_y+15+1, util.round(div), 2)
    screen.fill()
  end

  local function redraw_key2key3_widget()
    screen.move(key2_x+(key3_x-key2_x)/2, key2_y)
    screen.level(HI_LEVEL)
    screen.text("FINE")
  end

  local function redraw_key2_widget()
    screen.move(key2_x, key2_y)
    if state.prev_held then
      screen.level(HI_LEVEL)
    else
      screen.level(LO_LEVEL)
    end
    screen.text("PREV")
  end

  local function redraw_key3_widget()
    screen.move(key3_x, key3_y)
    if state.next_held then
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

  if state.fine then
    redraw_key2key3_widget()
  else
    redraw_key2_widget()
    redraw_key3_widget()
  end

  screen.update()
end

return Pages
