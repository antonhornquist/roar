-- shared logic for paged user interface
-- this file pollutes the global namespace

local UI = include('lib/ui') -- TODO: path from script root

HI_LEVEL = 15
LO_LEVEL = 4
FPS = 35

fine = false
prev_held = false
next_held = false

local Common = {}

local update_ui

local pages

function Common.init_ui(conf)
  if conf.arc then
    local arc_conf = conf.arc

    if not arc_conf.on_delta then
      arc_conf.on_delta = Common.default_arc_delta_handler -- TODO: check that this works
    end

    if not arc_conf.on_refresh then
      on_refresh = Common.default_arc_refresh_handler -- TODO: check that this works
    end

    UI.init_arc(arc_conf)
  end

  -- TODO: this section appears to be not so well thought, ought, it's all the same(?)
  local screen_conf
  if conf.screen then
    screen_conf = conf.screen
  else
    screen_conf { on_refresh = Common.default_screen_refresh_handler } -- TODO: check that this works
  end
  UI.init_screen(screen_conf)

  if conf.grid then
    UI.init_grid(conf.grid)
  end

  if conf.midi then
    UI.init_midi(conf.midi)
  end

  pages = conf.pages or {}
end

function Common.start_ui()
  local update_ui_metro = metro.init()
  update_ui_metro.event = update_ui
  update_ui_metro.time = 1/FPS
  update_ui_metro:start()
end

function update_ui()
  if target_page then
    update_page_transition()
  end
  UI.refresh()
end

function update_page_transition()
  current_page = current_page + page_trans_div
  page_trans_frames = page_trans_frames - 1
  if page_trans_frames == 0 then
    current_page = target_page
    target_page = nil
  end
  UI.set_dirty()
end

function Common.redraw()
  local enc1_x = 0
  local enc1_y = 12

  local enc2_x = 10
  local enc2_y = 29 -- 31 -- 33

  local enc3_x = enc2_x+65
  local enc3_y = enc2_y

  local page_indicator_y = enc2_y + 16 + 3

  local key2_x = 0
  local key2_y = 63

  local key3_x = key2_x+65
  local key3_y = key2_y

  local function draw_enc1_widget()
    screen.move(enc1_x, enc1_y)

    screen.level(LO_LEVEL)
    screen.text("LEVEL")
    screen.move(enc1_x+45, enc1_y)
    screen.level(HI_LEVEL)
    screen.text(util.round(mix:get_raw("output")*100, 1))
  end

  local function draw_event_flash_widget()
    screen.level(LO_LEVEL)
    screen.rect(122, enc1_y-7, 5, 5)
    screen.fill()
  end

  local function draw_bullet(x, y, level)
    screen.level(level)
    screen.rect(x, y, 2, 2)
    screen.fill()
  end

  local function translate(value, indicator_width)
    return util.round(indicator_width * value)
  end

  local function draw_value(ind_x, ind_y, ind_x_delta, level)
    local x = ind_x + ind_x_delta
    draw_bullet(x, ind_y, level)
  end

  local function strokedraw_value(ind_x, ind_y, min_value, max_value, level, width)
    local min_ind_x_delta = translate(min_value, width)
    local max_ind_x_delta = translate(max_value, width)
    for ind_x_delta=min_ind_x_delta, max_ind_x_delta do
      draw_value(ind_x, ind_y, ind_x_delta, level)
    end
  end

  local function draw_visual_values(ind_x, ind_y, width, visual_values)
    local max_level = 2 -- LO_LEVEL
    local num_visual_values = #visual_values.content
    if num_visual_values > 1 then
      local prev_visual_value = visual_values.content[1]
      for idx=2, num_visual_values do
        local visual_value = visual_values.content[idx]

        local min_visual_value = math.min(prev_visual_value, visual_value)
        local max_visual_value = math.max(prev_visual_value, visual_value)

        local level = util.round(max_level/num_visual_values*idx)

        strokedraw_value(ind_x, ind_y, min_visual_value, max_visual_value, level, width)

        prev_visual_value = visual_value
      end
    end
    --[[
    if num_visual_values == 2 then
      local prev_visual_value = translate(visual_values.content[1], width-2)
      local current_visual_value = translate(visual_values.content[2], width-2)
      local min_visual_value = math.min(prev_visual_value, current_visual_value)
      local max_visual_value = math.max(prev_visual_value, current_visual_value)
      strokedraw_value(ind_x, ind_y, min_visual_value, max_visual_value, max_level, width)
    end
    ]]
  end

  local function draw_ui_param(page, param_index, x, y)
    local ui_param = pages[page][param_index]
    screen.move(x, y)
    screen.level(LO_LEVEL)
    screen.text(ui_param.label)
    screen.move(x, y+12)
    screen.level(HI_LEVEL)
    screen.text(ui_param.format(ui_param.id))

    local ind_x = x + 1
    local ind_y = y + 14

    -- TODO: create PR for standard screen_extents function
    local label_width = _norns.screen_extents(ui_param.label) - 2 -- TODO, cache this in ind_width or similar instead

    local visual_values = ui_param.visual_values
    if visual_values then
      draw_visual_values(ind_x, ind_y, label_width, visual_values)
    end

    local value = params:get_raw(ui_param.id) -- TODO: refactor out params, should be an injected dependency
    draw_value(ind_x, ind_y, translate(value, label_width), HI_LEVEL)
  end

  local function draw_enc2_widget()
    local left = math.floor(current_page)
    local right = math.ceil(current_page)
    local offset = current_page - left
    local pixel_ofs = util.round(offset*128)

    draw_ui_param(left, 1, enc2_x-pixel_ofs, enc2_y)

    if left ~= right then
      draw_ui_param(right, 1, enc2_x+128-pixel_ofs, enc2_y)
    end

  end

  local function draw_enc3_widget()
    local left = math.floor(current_page)
    local right = math.ceil(current_page)
    local offset = current_page - left
    local pixel_ofs = util.round(offset*128)

    draw_ui_param(left, 2, enc3_x-pixel_ofs, enc3_y)

    if left ~= right then
      draw_ui_param(right, 2, enc3_x+128-pixel_ofs, enc3_y)
    end
  end
    
  local function draw_page_indicator()
    local div = 128/#pages

    screen.level(LO_LEVEL)

    screen.rect(util.round((current_page-1)*div), page_indicator_y, util.round(div), 2)
    screen.fill()
  end

  local function draw_key2key3_widget()
    --screen.move(126, key2_y)
    screen.move(key2_x+42, key2_y)
    screen.level(HI_LEVEL)
    screen.text("FN")
  end

  local function draw_key2_widget()
    screen.move(key2_x, key2_y)
    if prev_held and not fine then
      screen.level(HI_LEVEL)
    else
      screen.level(LO_LEVEL)
    end
    screen.text("PREV")
  end

  local function draw_key3_widget()
    screen.move(key3_x, key3_y)
    if next_held and not fine then
      screen.level(HI_LEVEL)
    else
      screen.level(LO_LEVEL)
    end
    screen.text("NEXT")
  end

  screen.font_size(16)
  screen.clear()

  draw_enc1_widget()

  if UI.show_event_indicator then
    draw_event_flash_widget()
  end

  draw_enc2_widget()
  draw_enc3_widget()

  draw_page_indicator()

  if fine then
    draw_key2key3_widget()
  end

  draw_key2_widget()
  draw_key3_widget()

  screen.update() -- TODO: screen should probably be considered a device in the screen { device = screen } conf
end

function Common.enc(n, delta)
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
    params:delta(Common.get_param_id_for_current_page(n-1), d)
  end
end

function Common.key(n, z)
  local page

  if target_page then
    page = target_page
  else
    page = get_active_page()
  end

  if n == 2 then
    if z == 1 then
      page = page - 1
      if page < 1 then
        page = #pages
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
      if page > #pages then
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

function Common.default_arc_delta_handler(n, delta)
  local d
  if fine then
    d = delta/5
  else
    d = delta
  end
  local id = Common.get_param_id_for_current_page(n)
  local val = params:get_raw(id)
  params:set_raw(id, val+d/500)
end

function Common.draw_arc(my_arc, value1, visual_values1, value2, visual_values2)
  local range = 44

  local function translate(n)
    n = util.round(n*range)
    return n
  end

  local function ring_map(n)
    if n < range/2 then
      n = 64-range/2+n
    else
      n = n-range/2
    end
    return n
  end

  local function ring_map_stroke(ring, start_n, end_n, level)
    for n=start_n, end_n do
      my_arc:led(ring, ring_map(n), level)
    end
  end

  local function draw_visual_values(ring, visual_values)
    local max_level = 2
    local num_visual_values = #visual_values.content
    if num_visual_values > 1 then
      local prev_led_n = translate(visual_values.content[1])
      for idx=2, num_visual_values do
        local led_n = translate(visual_values.content[idx])
        local min_n = math.min(prev_led_n, led_n)
        local max_n = math.max(prev_led_n, led_n)

        local level = util.round(max_level/num_visual_values*idx)

        ring_map_stroke(ring, min_n, max_n, level)

        prev_led_n = led_n
      end
    end
    --[[
    TODO
    if num_visual_values == 2 then
      print(ring, translate(visual_values.content[1]), translate(visual_values.content[2]), max_level)
      ring_map_stroke(ring, translate(visual_values.content[1]), translate(visual_values.content[2]), max_level)
    end
    ]]
  end

  local function draw_arc_ring_leds(ring, value, visual_values)
    for n=range/2, 64-range/2 do
      my_arc:led(ring, n, 1)
    end

    if visual_values then
      draw_visual_values(ring, visual_values)
    end

    local led_n = ring_map(translate(value))

    my_arc:led(ring, led_n, 15)
  end

  my_arc:all(0)
  draw_arc_ring_leds(1, value1, visual_values1)
  draw_arc_ring_leds(2, value2, visual_values2)
end

function set_page(page)
  current_page = page
end

function get_active_page()
  return util.round(current_page)
end

Common.get_active_page = get_active_page

function Common.get_param_id_for_current_page(n)
  local page = get_active_page()
  return pages[page][n].id
end

function transition_to_page(page)
  target_page = page
  page_trans_frames = FPS/5
  page_trans_div = (target_page - current_page) / page_trans_frames
end

function Common.new_capped_list(capacity)
  return {
    capacity=capacity,
    content={}
  }
end

function Common.push_to_capped_list(list, value)
  if #list.content > list.capacity then
    table.remove(list.content, 1)
  end
  table.insert(list.content, value)
end

-- shared logic for loading / saving settings
-- this file pollutes the global namespace

function Common.load_settings()
  local fd=io.open(norns.state.data .. SETTINGS_FILE,"r")
  local page
  if fd then
    io.input(fd)
    local str = io.read()
    io.close(fd)
    if str ~= "" then
      page = tonumber(str)
    end
  end
  set_page(page or 1)
end

function Common.save_settings()
  local fd=io.open(norns.state.data .. SETTINGS_FILE,"w+")
  io.output(fd)
  io.write(get_active_page() .. "\n")
  io.close(fd)
end

function Common.default_arc_refresh_handler(my_arc)
  Common.render_active_page_on_arc(my_arc)
end

function Common.render_active_page_on_arc(my_arc)
  local page = pages[get_active_page()]

  Common.draw_arc(
    my_arc,
    params:get_raw(Common.get_param_id_for_current_page(1)),
    page[1].visual_values,
    params:get_raw(Common.get_param_id_for_current_page(2)),
    page[2].visual_values
  )
end

function Common.set_ui_dirty()
  UI.set_dirty()
end

return Common
