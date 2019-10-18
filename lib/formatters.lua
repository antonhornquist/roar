-- utility library for paging UI

local Formatters = {}

function Formatters.percentage(value)
  return util.round(value*100, 1) .. "%"
end

function Formatters.adaptive_time(ms)
  if util.round(ms, 1) < 1000 then
    return util.round(ms, 1) .. "ms"
  elseif util.round(ms, 1) < 10000 then
    return util.round(ms/1000, 0.01) .. "s"
  else
    return util.round(ms/1000, 0.1) .. "s"
  end
end

function Formatters.adaptive_freq(hz)
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

return Formatters
