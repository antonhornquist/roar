local CappedList = {}

function CappedList.create(capacity)
  local cl = {
    capacity=capacity,
    content={}
  }
  return cl
end

function CappedList.push(cl, value)
  if #cl.content > cl.capacity then
    table.remove(cl.content, 1)
  end
  table.insert(cl.content, value)
end

return CappedList
