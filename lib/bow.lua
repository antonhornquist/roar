-- self contained utility library for rendering a 0 .. 1.0 parameter value onto a ring with optional historical parameter values

local spawn_render_ring_function
local assert_equal

local run_tests = function()
  local render_ring = spawn_render_ring_function(8, 5)

  assert_array_equal(
    render_ring(0),
    {0, 0, 0, 5, 5, 5, 15, 0}
  )

  assert_array_equal(
    render_ring(0.25),
    {0, 0, 0, 5, 5, 5, 0, 15}
  )

  assert_array_equal(
    render_ring(0.5),
    {15, 0, 0, 5, 5, 5, 0, 0}
  )

  assert_array_equal(
    render_ring(0.75),
    {0, 15, 0, 5, 5, 5, 0, 0}
  )

  assert_array_equal(
    render_ring(1),
    {0, 0, 15, 5, 5, 5, 0, 0}
  )

  assert_array_equal(
    render_ring(0, { 0.5 }),
    {0, 0, 0, 5, 5, 5, 15, 0}
  )

  assert_array_equal(
    render_ring(0, { 0.5, 0.75 }),
    {2, 2, 0, 5, 5, 5, 15, 0}
  )

  assert_array_equal(
    render_ring(0, { 0.5, 0.75, 1 }),
    {1, 2, 2, 5, 5, 5, 15, 0}
  )

  print("tests ok")
end

local arrays_are_equal
local array_as_string

assert_array_equal = function(a, b)
  if not arrays_are_equal(a, b) then
    error("assertion failed, expected a == b, actual "..array_as_string(a).." != "..array_as_string(b))
  end
end

arrays_are_equal = function(arr1, arr2)
  for i,element in ipairs(arr1) do
    if element ~= arr2[i] then
      return false
    end
  end
  return true
end

array_as_string = function(array)
  local str = ""
  for i, element in ipairs(array) do
    str = str .. element
    if i ~= #array then
      str = str .. ", "
    end
  end
  return str
end

local round
local clip

spawn_render_ring_function = function(num_ring_leds, num_ring_led_range)
  local render_base
  local render_range

  local render_ring = function(value, visual_values)
    local led_levels = {}
    render_base(led_levels, 5)
    render_range(led_levels, value, visual_values)
    return led_levels
  end

  render_range = function(led_levels, value, visual_values)
    local top_led_index = ((num_ring_led_range-1)/2)
    local num_base_leds = (num_ring_leds - num_ring_led_range)

    local range_led_levels = {}
    for i=1,num_ring_led_range do
      range_led_levels[i] = 0
    end

    local translate
    local render_range

    local render_visual_values = function(visual_values, max_level)
      local num_visual_values = #visual_values
      local prev_led_n, led_n, max_led_n, min_led_n, level

      if num_visual_values > 1 then
        prev_led_n = translate(visual_values[1])
        for offset_idx=1,(num_visual_values-1) do
          led_n = translate(visual_values[offset_idx+1])
          max_led_n = math.max(prev_led_n, led_n)
          min_led_n = math.min(prev_led_n, led_n)

          level = math.floor(math.max(round(max_level/(num_visual_values-1)*offset_idx), 1))

          render_range(min_led_n, max_led_n, level)

          prev_led_n = led_n
        end
      end
    end

    local render_led

    local render_value = function(value, level)
      render_led(translate(value), level)
    end

    translate = function(value)
      return round(clip(value, 0, 1)*(num_ring_led_range-1))
    end

    render_range = function(start_n, end_n, level)
      for led_n=start_n,end_n do
        render_led(led_n, level)
      end
    end

    render_led = function(led_index, level)
      range_led_levels[led_index+1] = level
    end

    if visual_values then
      render_visual_values(visual_values, 2)
    end

    render_value(value, 15)

    for led_index, level in ipairs(range_led_levels) do
      local idx
      if led_index <= top_led_index then
        idx = top_led_index + num_base_leds + led_index + 1
      else
        idx = led_index - top_led_index
      end
      led_levels[idx] = level
    end
  end

  render_base = function(led_levels, level)
    local num_base_leds = (num_ring_leds - num_ring_led_range)
    local base_start = (num_ring_led_range-1)/2+1
    for index=1,num_base_leds do
      led_levels[base_start+index] = level
    end
  end

  num_ring_leds = num_ring_leds or 64
  num_ring_led_range = num_ring_led_range  or 45 -- should be an odd number

  return render_ring
end

round = function(number, quant)
  if quant == 0 then
    return number
  else
    return math.floor(number/(quant or 1) + 0.5) * (quant or 1)
  end
end

clip = function(number, low, high)
  if number < low then
    return low
  elseif number > high then
    return high
  else
    return number
  end
end

run_tests() -- uncomment to run tests
return spawn_render_ring_function
