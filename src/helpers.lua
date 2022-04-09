function dump(o)
  if type(o) == 'table' then
    local s = '{ '
    for k,v in pairs(o) do
      if type(k) ~= 'number' then k = '"'..k..'"' end
      s = s .. '['..k..'] = ' .. dump(v) .. ','
    end
    return s .. '} '
  else
    return tostring(o)
  end
end

function table.shallow_copy(t)
  local t2 = {}
  for k,v in pairs(t) do
    t2[k] = v
  end
  return t2
end


function textrect(text,x,tey,w)
  words = mysplit(text)
  tex = x
  for _,word in pairs(words) do
    tw = print(word, 0, -10, 15, false, 1, true)
    if tex + tw > x + w then
      tex = x
      tey = tey + 6
    end
    prints(word, tex, tey, 15, false, 1, true)
    tex = tex + tw + 6
  end
end

function eitheror(a,b,pa,r)
  r = (r * 17 + a * 23 + b * -7) * 111 + (r * 11 + a * -3 + b * 29) * 97
  if math.abs(r) % 100 > pa * 100 then
    return b
  else
    return a
  end
end

function mysplit (inputstr, sep)
  if sep == nil then
    sep = "%s"
  end
  local t={}
  for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
    table.insert(t, str)
  end
  return t
end

--Prints text where x is the center of text.
function printc(s,x,y,c,fixed,scale,small)
  local w=print(s,0,-8,c or 15,true)
  prints(s,x-(w/2//6*6),y,c or 15,fixed,scale,small)
end

--Prints text, replaces some symbols with sprites
function prints(s,x,y,c,fixed,scale,small)
  scale = scale or 1
  print(s:gsub("%$"," "):gsub("/"," "):gsub("#"," "):gsub("%*"," "):gsub("@"," "),x,y+1,c or 15, true,scale,small)
  for i = 1, s:len() do
    ch = s:sub(i,i)
    sp = 0
    if(ch == "#") then -- stone
      sp = 128
    end
    if(ch == "/") then -- wood
      sp = 129
    end
    if(ch == "$") then -- score
      sp = 130
    end
    if(ch == "*") then -- time
      sp = 131
    end
    if(ch == "@") then -- card
      sp = 132
    end
    spr(sp,x+(i-1)*6,y,0)
  end
end

function timestring(time, compact)
  if compact then
    return string.format("%d%s", math.floor(time / wt), re_symbols[4])
  else
    return string.format("%1.1f%s", time / wt, re_symbols[4])
  end
end

function coststring(cost, extratime, compact)
  extratime = extratime or 0
  str = ""
  for i = 1,5 do
    co = cost[i] or 0
    if i ~= 4 and co > 0 then
      if string.len(str) > 0 then
        if compact then
          str = str .. " "
        else
          str = str .. ", "
        end
      end
      str = string.format("%s%d%s", str, co, re_symbols[i])
    end
  end
  time = (cost[4] or 0) + extratime
  if time > 0 then
    if string.len(str) > 0 then
      if compact then
        str = str .. " "
      else
        str = str .. ", "
      end
    end
    str = str .. timestring(time, compact)
  end
  return str
end