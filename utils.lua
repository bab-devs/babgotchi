function clear()
  particles = {}
  frames = 0
  fpstimer = 0
  fps = 0
  oldmousex = 0
  oldmousey = 0
  babx = 0
  baby = 0
  babxvel = 0
  babyvel = 0
  babfacing = 1
  babhappy = false
  babhappytimeout = false
  babhunger = 40
  babhungertimeout = false
  babmood = 20
  babmoodtimeout = false
  func_queue = {}
end

function hslToRgb(h, s, l, a)
  local r, g, b

  if s == 0 then
      r, g, b = l, l, l -- achromatic
  else
      function hue2rgb(p, q, t)
          if t < 0   then t = t + 1 end
          if t > 1   then t = t - 1 end
          if t < 1/6 then return p + (q - p) * 6 * t end
          if t < 1/2 then return q end
          if t < 2/3 then return p + (q - p) * (2/3 - t) * 6 end
          return p
      end

      local q
      if l < 0.5 then q = l * (1 + s) else q = l + s - l * s end
      local p = 2 * l - q

      r = hue2rgb(p, q, h + 1/3)
      g = hue2rgb(p, q, h)
      b = hue2rgb(p, q, h - 1/3)
  end

  return {r, g, b}
end


function pointOverBox(x,y,x2,y2,w,h)
  return x > x2 and x < x2+w and y > y2 and y < y2+h
end

function mouseOverBox(x,y,w,h)
  return pointOverBox(love.mouse.getX(),love.mouse.getY(),x,y,w,h)
end


function string.starts(str, start)
  return str:sub(1, #start) == start
end

function string.ends(str, ending)
  return ending == "" or str:sub(-#ending) == ending
end

function deleteActions(func, timeAhead)
  for i,qf in ipairs(func_queue) do
    if (qf[1] == func or not func) and (qf[3] == timeAhead or not timeAhead) then
      table.remove(func_queue, i)
    end
  end
end

function queueAction(func, timeAhead)
  table.insert(func_queue, {func, love.timer.getTime(), timeAhead})
end

function limit(value, min, max)
  if max and value >= max then
    return max
  elseif min and value <= min then
    return min
  else
    return value
  end
end

function table.match(t, mth)
  local returntables = {}
  for _,object in pairs(t) do
    local returntable = true

    for i,matchobject in pairs(mth) do
      if object[i] ~= matchobject then
        returntable = false
      end
    end
    
    if returntable then
      table.insert(returntables, object)
    end
  end

  return returntables
end