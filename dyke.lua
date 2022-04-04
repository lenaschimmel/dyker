--
-- title:  dyke march
-- author: lena schimmel
-- desc:   a game for ld50
-- script: lua
t=0 --global time
px=12 -- player x (y is not saved, but computed)
tx=12 -- target x (to walk to)

bx=0 -- build target x
by=0 -- build target y
tb=nil -- to build (nil or object)
to=1 -- tool (1=walk, 2=build, 3=collect, 4=cut, 5=card)
wo = false -- working, time passing, accept no input during this
tl = 0

pf=0 -- player flip (walking direction)
sx=0 -- scroll x in pixel
sb = 30 -- scroll sensitive border
re = {0, 0, 0} -- ressources (stone, wood, score)
wt = 100 -- water tics
pt = 10 -- player tics
tm = 100 -- target money = win condition

levelindex = 1
selectedcard = 0
buildingcard = nil

function start() 
  loadlevel(1)
end

function lmget(x,y)
  return mget(x+levelx, y+levely)
end

function lmset(x,y,t)
  mset(x+levelx, y+levely, t)
end

re_names={"stone", "wood", "coins", "time"}
re_symbols={"#", "/", "$", "*"}
to_names={"walk", "build dyke", "collect", "cut", "wait", "play card"}

levels = {
  {
    name = "Introduction",
    x = 30,
    y = 34,
    w = 30,
    m = 70,
    re = {5, 0, 0}
  },
  {
    name = "Level two",
    x = 0,
    y = 0,
    w = 60,
    m = 100,
    re = {5, 0, 0}
  },
}

objecttypes = {
  {
    name="dyke",
    cost={1,0,0,60},
    desc="stops water and you can walk on it",
    sx=1,
    sy=1,
    sprites={70,38,54,54,54},
    isblock=true,
    spoutline=70,
    spoutlinered=86,
  },
  {
    name="rock",
    cost={0,0,0,0},
    desc="you can harvest stones from it",
    sx=2,
    sy=2,
    sprites={48,48,48,48,48},
    isblock=false,
    cut = {
      verb = "break",
      re = 10,
      gain = {1,0,0,0},
      time = 100
    },
    draw = function(o)
      x = o.x*8-sx
      y = o.y*8
      if o.cut.re > 6 then
        spr(48,x,y,0, 1, 0, 0, 2, 2)
      elseif o.cut.re > 2 then
        spr(48,x,y+8,0, 1, 0, 0, 2, 1)
      elseif o.cut.re > 0 then
        spr(33,x,y+8,0, 1)
      end
    end 
  },
  {
    name="tree",
    cost={0,0,0,0},
    desc="you can collect apples from it, or cut it for wood.",
    sx=2,
    sy=2,
    sprites={75,39,11,41,45},
    isblock=false,
    cut = {
      verb = "cut",
      re = 0,
      gain = {0,10,0,0},
      time = 250
    },
    collect = {
      verb = "pick",
      re = 0,
      gain = {0,0,3,0},
      time = 10
    },
    create = function(o)
      o.ttg = 300
      o.tta = 200
      o.state = 2
    end,

    update = function(o)
      if o.ttg > 0 then
        o.ttg = o.ttg - 1
      elseif o.state == 2 then
        o.state = 3
        o.cut.re = 1
        stopwait()
      end

      if o.state == 3 then
        if o.tta > 0 then
          o.tta = o.tta - 1
        end
        if o.tta == 0 then
          o.tta = 200
          if o.collect.re < 4 then
            stopwait()
          end
          o.collect.re = math.min(4,o.collect.re+1)
        end
      end

      if o.state ~= 5 then
        for xx = o.x, o.x+o.type.sx-1 do
          for yy = o.y, o.y+o.type.sy-1 do
            if iswater(xx,yy) then
              o.state = 5
              o.collect.re = 0
              o.cut.re = 0
            end
          end
        end
      end
    end,

    canwait = function(o) 
      return o.state < 4 and o.collect.re < 4
    end,

    draw = function(o)
      if o.state == 3 and o.cut.re == 0 then
        o.state = 4
      end
      x = o.x*8-sx
      y = o.y*8
      sp = o.type.sprites[o.state]
      if o.ttg > 0 then
        sp = 39
      end
      if o.state == 3 then
        n = 0
        for xi = 0,1 do
          for yi = 0,1 do
            off = 0
            n = n + 1
            if (o.collect.re >= n) then
              off = 32
            end
            spr(sp + xi + 16 * yi + off,x + xi*8,y+yi*8,0, 1)
          end
        end
      else
        spr(sp,x,y,0, 1, 0, 0, 2, 2)
      end
    end 
  },
}

objects = {}
cards = {}

function canwait() 
  for _,o in pairs(objects) do
    if o.type.canwait and o.type.canwait(o) then
      return true
    end
  end
  return false
end

function createobject(type,tx,ty)
  object = {
    type = type,
    x = tx,
    y = ty,
    state = 1,
    cut = {
       re = 0
    },
    collect = { 
      re = 0
    }
  }
  if type.cut then
    object.cut.re = type.cut.re
  end
  if type.collect then
    object.collect.re = type.collect.re
  end
  if type.create then
    type.create(object)
  end
  table.insert(objects, object)
  for xx = tx, tx+type.sx-1 do
    for yy = ty, ty+type.sy-1 do
      lmset(xx,yy, 4)
    end
  end
  return object
end

function destroyobject(o)
  o.state = 4
  for xx = o.x, o.x+o.type.sx-1 do
    for yy = o.y, o.y+o.type.sy-1 do
      lmset(xx,yy, 0)
    end
  end
end

function drawobject(o)
  ty = o.type
  if ty.draw then
    ty.draw(o)
  else 
    sp = ty.sprites[o.state]
    spr(sp,o.x*8-sx,o.y*8,0, 1, 0, 0, ty.sx, ty.sy)
  end 
end


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

function loadlevel(i)
  definecards()
  levelwidth = levels[i].w
  levelheight = 17
  levelx = levels[i].x
  levely = levels[i].y
  tm = levels[i].m
  re = levels[i].re -- TODO deepcopy?

  t=0 --global time
  px=12 -- player x (y is not saved, but computed)
  tx=12 -- target x (to walk to)

  bx=0 -- build target x
  by=0 -- build target y
  tb=nil -- to build (nil or object)
  to=1 -- tool (1=walk, 2=build, 3=collect, 4=cut, 5=wait, 6=card)
  wo = false -- working, time passing, accept no input during this
  tl = 0

  pf=0 -- player flip (walking direction)
  sx=0 

  objects = {}

  for x=0,levelwidth do
    for y=0,levelheight do
      type = nil
      if lmget(x,y) == 224 then
        type = objecttypes[2]
      end
      if lmget(x,y) == 75 then
        type = objecttypes[3]
      end
      if type then
        o = createobject(type,x,y)
      end
    end
  end
end

function OVR()
  map(levelx,levely,levelwidth,levelheight,-sx,0,0)

  x,y,l = mouse()
  my = y // 8

  -- show resources
  te = string.format("%2d# %2d/ %4d$",re[1],re[2],re[3])
  prints(te, 6, 8, 12)

  -- show actions
  prints("Action:", 16*6, 8, 12)
  for i=1,6 do
    spr(95 + i, 132 + 12*i, 8, 0)
    if to==i then
      spr(104, 132 + 12*i, 8, 0)
    end
  end
  prints(""..#handcards, 212, 8, 14)

  ct = "" --center text
  -- draw cursor, handle potential actions
  local sp = 119

  if to==6 then
    sp = 119
    local ci, bu = paintcards(x/8, y/8)
    if bu then
      card = handcards[ci]
      mis = canpay(card.cost)
      if mis > 0 then
        sp = 164
        ct = "Not enough " .. re_symbols[mis] .. " to play '" .. card.title .. "'"
        paintcardonlybutton(ci, 2)
      else
        sp = 148
        ct = "Play the card '" .. card.title .. "'"
        paintcardonlybutton(ci, 5)
        if l then
          pay(card.cost)
          selectedcard = 0
          trace("Remove card " .. ci)
          table.remove(handcards, ci)
          if card.action then
            card.action()
          elseif card.gain then
            gain(card.gain)
          end

          if card.ispermanent then
            table.insert(permanteds, card)
          end

          if card.buildingtype then
            buildingcard = card

          end
        end
      end
    elseif ci > 0 and selectedcard ~= ci then
      ct = "Look at card '" .. handcards[ci].title .. "'"
    elseif ci == 0 and selectedcard > 0 then
      ct = "Move card out of the way"
    end
    if l then
      selectedcard = ci
    end
  end

  if my > 2 then -- lower screen part
    if wo then
      sp = 102
    else
      if to ~= 6 then
      sp = 159 + to -- disabled
      end
      if to == 1 then -- walk
        ly = yabovefloor(mx)
        if iswalkable(mx,my) then
          if isreachable(mx,ly) then
            if ly ~= my then
              spr(122,mx*8-sx,ly*8,0)
            end
            sp = sp - 16 -- enable
            ct = "Walk here: " .. timestring(walktimetox(mx))
            if l then
              tx = mx
              wo = true
            end
          else
            spr(138,mx*8-sx,ly*8,0)
            ct = "Not reachable"
          end
        else
          ct = "Not walkable"
        end
      end

      if to == 2 then -- build
        ty = objecttypes[1]
        mis = canpay(ty.cost)
        if mis > 0 then
          ct = "Not enough " .. re_symbols[mis] .. " to build " .. ty.name
        elseif not isvaliddykepos(mx,my) then
          ct = "Cant build " .. ty.name .. " here"
          sp = ty.spoutlinered -- no real cursor, we draw the building outline
        else
          sp = ty.spoutline -- no real cursor, we draw the building outline
          left = mx
          right = mx + ty.sx - 1
          ptx = workpoint(left, right)
          if isreachable(ptx, my) then
            ct = "Build " .. ty.name .. " here: " .. coststring(ty.cost, walktimetox(ptx))
            if l then
              tx = ptx
              bx = mx
              by = my
              pay(ty.cost)
              wo = true
              tb = createobject(ty,mx,my)
              if left > px then -- must reach to the right
                pf = 1
              elseif right < px then -- must reach to the left
                pf = 0
              end
            else
              ct = "Can't reach this place."
            end
          end
        end
        spr(sp,mx*8-sx,my*8,0,1,0,0,ty.sx, ty.sy)
      end

      if to == 3 or to == 4 then -- collect / cut
        for _,o in pairs(objects) do
          ty = o.type
          left = o.x
          right = o.x + ty.sx -1
          ptx = workpoint(left, right)
          if mx >= left and mx <= right and my >= o.y and my <= o.y + ty.sy -1 then
            action = nil

            releft = 0
            if to == 3 and ty.collect then
              action = ty.collect
              releft = o.collect.re
            elseif to == 4 and ty.cut then
              action = ty.cut
              releft = o.cut.re
            end

            if action then
              if releft > 0 then
                if isreachable(ptx, my) then
                  sp = sp - 16 -- enable
                  ct = action.verb .. " " .. ty.name .. " to get " .. coststring(action.gain) .. ": " .. timestring(walktimetox(ptx) + action.time) .. " ("..releft.."x left)"
                  if l then
                    tb = o
                    wo = true
                    tx = ptx
                    tl = 0
                  end
                else
                  ct = "Can't reach this place."
                end
              else
                ct = "nothing to " .. action.verb .. " there"
              end
            end
          end
        end
      end

    end
    spr(sp,mx*8-sx,my*8,0)
  else -- upper screen part
    mxc = x // 6
    if wo then
      sp = 102
    else
      if my == 1 then
        for i = 1,3 do
          if mxc > i*4 - 4 and (mxc < i*4 or (i==3 and mxc < i*4+2)) then
            ct =  re[i] .. " " .. re_names[i]
            if i == 3 then
              ct = ct .. " (earn " .. tm .. "$ to win)"
            end
          end
        end
        for i=1,6 do
          if mxc == 22 + 2*i then
            sp = 120
            ct = to_names[i]
            if i == 5 then -- wait
              if not canwait() then
                ct = "Nothing to wait for"
                sp = 136
              end
            end

            if i == 6 then -- card
              if #handcards == 0 then
                ct = "No cards"
                sp = 136
              end
            end
            
            if l then
              if (i ~= 5 or canwait()) and (i ~= 6 or #handcards > 0) then
                to = i
              end
              if to == 5 and canwait() then
                wo = true
              end
            end
          end
        end
      end
    end
    spr(sp,mxc*6,my*8,0) -- cursor
  end
  printc(ct, 120, 0, 12)
end

function stopwait()
  if to == 5 then
    to = 0
    wo = false
  end
end

function workpoint(left, right)
  if px < left then
    ptx = left - 1
  elseif px > right then
    ptx = right + 1
  else
    ptx = px
  end
  return ptx
end

function walktimetox(x)
  return  math.abs(px - x) * pt
end

function canpay(cost)
  for i = 1,3 do
    if re[i] < cost[i] then
      return i
    end
  end
  return 0
end

function pay(cost)
  for i = 1,3 do
    re[i] = re[i] - cost[i]
  end
end

function earn(gain)
  for i = 1,3 do
    re[i] = re[i] + gain[i]
  end

  if re[3] > tm then
    trace("Level won")
    levelindex = levelindex + 1
    if #levels < levelindex then
      trace("Game won")
      -- TODO
    else
      loadlevel(levelindex)
    end
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
  for i = 1,3 do
    co = cost[i] or 0
    if co > 0 then
      if compact then
        str = str .. " "
      else
        str = str .. ", "
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

function TIC()
  -- mouse calc
  x,y,l,_,_,sxv = mouse()
  -- mouse position in grid coords
  mx = math.floor((x+sx) / 8)
  mxa = math.floor(x / 8)
  my = math.floor(y / 8)

  -- update scroll
  if x < sb then
    sv = sb - x
    sx = sx - sv * sv / 400
  end
  if x > (240 - sb) then
    sv = x - (240 - sb)
    sx = sx + sv * sv / 400
  end
  sx = sx + sxv * 2
  sx = math.max(sx, 0)
  sx = math.min(sx, (levelwidth * 8) - 240)

  movecards()

  -- update
  if wo then
    t=t+1

    --update objects
    for _,o in pairs(objects) do
      if o.type.update then
        o.type.update(o)
      end
    end

    if px ~= tx then -- still walking
      if t % pt == 0 then
        if px < tx then
          px = px + 1
            pf = 1
        else
          px = px - 1
          pf = 0
        end
      end
    else -- doing something else
      if to == 1 then -- walk
        wo = false
      end

      if to == 2 and tb ~= nil then
        if tb.state == 1 then -- planned -> building
          tb.state = 2
          tl = tb.type.cost[4]
        elseif tb.state == 2 then -- building -> finished
          tl = tl - 1
          if tl <= 0 then
            tb.state = 3
            if tb.type.isblock then
              lmset(tb.x,tb.y,3)
            end
            tb = nil
            wo = false
          end
        end
      end

      action = nil
      if tb then
        ty = tb.type
        if to == 3 then
          action = ty.collect
        end
        if to == 4 then
          action = ty.cut
        end
        if action then -- collect or cut 
          if tl == 0 then -- start doing it
            tl = action.time
          end
          
          tl = tl - 1
          if tl <= 0 then -- finished doing it
            if to == 3 then
              tb.collect.re = tb.collect.re - 1
            end
            if to == 4 then
              tb.cut.re = tb.cut.re - 1
              if tb.cut.re == 0 then
                destroyobject(tb)
              end
            end
            earn(action.gain)
            tb = nil
            wo = false
          end
        end
      end
    end
    
    if t % wt == 0 then
      addwater()
      t = 0
    end
  end

  -- draw map
  cls(11)
  map(levelx,levely+17,levelwidth,levelheight,-sx,0,0)

  -- draw objects
  for _,o in pairs(objects) do
    drawobject(o)
  end
	
  -- draw player
  py = yabovefloor(px)
  body = 7
  legs = 23
  pfb = pf -- body flip
  if not wo then
    if my < py - 4 then
      body = 52
    elseif mx < px - 4 then
      pfb = 0
    elseif mx > px + 4 then
      pfb = 1
    else
      body = 53
    end
  end
  if wo and px ~= tx then
    legs = 68
    if t % 10 >= 5 then
      legs = 69
    end
  end
  if wo and to > 1 and to < 5 then
    dx = px - 1 + 2 * pf
    spr(50,dx*8-sx,(py-1)*8,0, 1, pf) -- arm
    spr(to+79,dx*8-sx,(py-0)*8,0, 1, pf) -- tool
    body = 51 -- no double arm
    legs = 67
  end
  spr(body,px*8-sx,(py-1)*8,0, 1, pfb) -- body
  spr(legs,px*8-sx,(py-0)*8,0, 1, pf) -- legs

end

function yabovefloor(x)
  for y = 0,18,1 do
    if isblock(x,y) then
      return y - 1
    end	
	end
  return -1
end

function rightmostwater()
  for x = levelwidth, 0, -1 do
    for y = 0, levelheight, 1 do
      if iswater(x,y) then
        return x,y
      end
    end
  end
  return 0,15
end

function addwater()
  x,y = rightmostwater()
  
  if x == levelwidth - 1 then
    trace ("GAME OVER")
    exit()
    return
  end
  
  if isfloodable(x+1, y) then
    while isfloodable(x+1,y+1) do
      y = y + 1
    end
  	setwater(x+1, y)
   return
  end
  
  while x > 0 and isfloodable(x-1,y) do
    x = x - 1
  end
  
  if isfloodable(x,y) then
    while isfloodable(x+1,y+1) do
      y = y + 1
    end
    setwater(x+1, y)
  else
    y = y - 1
    while x > 0 and isfloodable(x-1,y) do
      x = x - 1
    end
    setwater(x,y)
  end
end

function setwater(x,y)
  if isblock(x+1,y) then
    lmset(x, y+levelheight, 17)
  else
    lmset(x, y+levelheight, 18)
  end
  if iswater(x-1,y) then
    lmset(x-1, y+levelheight, 17)
  end
  if iswater(x,y+1) then
    lmset(x, y+1+levelheight, 2)
  end
end

-- tile flags:
-- 0 = water
-- 1 = blocks water, can stand upon
-- 2 = blocks building

function iswater(x,y)
  return fget(lmget(x,y+levelheight),0)
end

function isblock(x,y)
  return fget(lmget(x,y),1)
end

function setblock(x,y)
  return lmset(x,y+levelheight,3)
end

-- does not test reachability, only if it was allowed to actually *be* there
function iswalkable(x,y)
  return not fget(lmget(x,y),1) and not iswater(x,y)
end

function isreachable(x,y)
  minx = math.min(x,px)
  maxx = math.max(x,px)
  lasth = yabovefloor(minx)
  for i = minx, maxx do
    h = yabovefloor(i)
    if h < 0 or iswater(i, h) then
      return false
    end
    d = math.abs(h - lasth)
    lasth = h
    if d > 1 then
      return false
    end
  end
  return true
end

-- can this grid pos hold water, but does currently not?
function isfloodable(x,y)
  return not fget(lmget(x,y),1) and not iswater(x,y)
end

function isbuildable(x,y)
  return not fget(lmget(x,y),2) and not iswater(x,y)
end

function isvaliddykepos(x,y)
	return isbuildable(x,y) and isblock(x-1,y+1) and isblock(x,y+1) and isblock(x+1,y+1)
end

--Prints text where x is the center of text.
function printc(s,x,y,c,fixed,scale,small)
  local w=print(s,0,-8,c or 15,true)
  prints(s,x-(w/2//6*6),y,c or 15,fixed,scale,small)
end

--Prints text, replaces some symbols with sprites
function prints(s,x,y,c,fixed,scale,small)
  scale = scale or 1
  print(s:gsub("%$"," "):gsub("/"," "):gsub("#"," "):gsub("%*"," "),x,y+1,c or 15, true,scale,small)
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

function myspr(sp, x, y)
  spr(sp, x*8, y*8, 0)
end

function myrspr(spa, spb, x, y, pa, r)
  sp = eitheror(spa, spb, pa, r * 13 + x * 19 + y * -5)
  spr(sp, x*8, y*8, 0)
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

function paintcardonlybutton(i, c)
  ci, button = 0, false
  -- effective width: 30 - 9 - 2 = 19
  wpc = 19 // (#handcards - 1)
  card = handcards[i]

  cx = 1 + (i-1) * wpc
  
  paintcardbutton(cx*8+9*4, (card.y+13-1)*8 - 6,c)
end

function paintcard(x,y,w,h,title,text,cost,r)
  myspr(204, x,y)
  myspr(207, x+w-1,y)
  myspr(252, x,y+h-1)
  myspr(255, x+w-1,y+h-1)
  stains = {222, 237, 238}
  for xx = x+1, x+w-2 do
    for yy = y+1, y+h-2 do
      stain = stains[math.abs(r*2+x*19+y*17)%3+1]
      myrspr(stain, 221, xx,yy, 0.03, r)
    end
    myrspr(205, 206, xx,y, 0.1, r)
    myrspr(253, 254, xx,y + h - 1, 0.25, r)
  end
  for yy = y+1, y+h-2 do
    myrspr(220, 236, x,yy, 0.1, r)
    myrspr(223, 239, x + w - 1,yy, 0.25, r)
  end
  myspr(216, x+1,y+3)
  for xx = x+2, x+w-3 do
    myspr(217, xx,y+3)
  end
  myspr(218, x+w-2,y+3)
  print(title, x*8+6, y*8 + 6, 15)
  prints(coststring(cost, 0, true), x*8, (y+2)*8)
  paintcardbutton(x*8+w*4, (y+h-1)*8 - 6, 9)

  if y > 13 then
    return
  end
  
  words = mysplit(text)
  tex = x*8+6
  tey = (y+4)*8+6
  for _,word in pairs(words) do
    tw = print(word, 0, -10, 15, false, 1, true)
    if tex + tw > x*8 + w*8 - 6 then
      tex = x*8+6
      tey = tey + 6
    end
    prints(word, tex, tey, 15, false, 1, true)
    tex = tex + tw + 6
  end
end

function paintcardbutton(x,y,c)
  printc("PLAY CARD", x, y, c)
end

function table.shallow_copy(t)
  local t2 = {}
  for k,v in pairs(t) do
    t2[k] = v
  end
  return t2
end

function definecards()
  
  cards = {
    {
      title="Woodseller",
      text="When you cut a tree for #, you get 10$ extra.",
      cost = {0,0,5,120},
      r=234,
    },
    {
      title="Boots",
      text="With these boots, you can walk 20% faster.",
      cost = {0,1,0,0},
      r=235,
    },
    {
      title="Well",
      text="The well allows you to water your plants, so their fruit will only take 60% of the time to grow.",
      cost = {5,0,0,300},
      r=236,
    }
  }
  for i, card in pairs(cards) do
    card.y = 14
  end
  handcards = {}
  for i = 1,5 do
    ind = math.random(1, #cards)
    trace("Add card " .. ind .. " to hand")
    table.insert(handcards, table.shallow_copy(cards[ind]))
  end
end

function movecards()
  for i, card in pairs(handcards) do
    if i == selectedcard then
      if card.y > 2 then
        card.y = card.y - 1
      end
    else
      if card.y < 14 then
        card.y = card.y + 1
      end
    end
  end
end

function paintcards(mx,my) 
  ci, button = 0, false
  -- effective width: 30 - 9 - 2 = 19
  wpc = 19 // (#handcards - 1)
  for i, card in pairs(handcards) do
    cx = 1 + (i-1) * wpc
    paintcard(cx,card.y,9,13,card.title, card.text, card.cost, card.r)
    if mx >= cx and mx <= cx + 9 and my >= card.y and my <= card.y + 13 then
      ci = i
      if mx >= cx + 1 and mx < cx + 9 - 1 and my >= card.y + 13 - 2 and my < card.y + 13 - 1 then
        button = true
      end
    end
  end
  return ci, button
end

start()


-- <TILES>
-- 001:3333333434333333333433333333333333333343334333333333433343333333
-- 002:9999999999999989998999999999999999999989999999999899989999999999
-- 003:eeeeedeeeeeefdeeeeeffdeeddddddddeedeeeeeefdeeeeeffdeeeeedddddddd
-- 005:65665566776476763773473737333433343333433343343434334f334f333333
-- 007:0033330000ccc330009c9c3000cccc30000cc330066666606066660660666606
-- 008:3433333333433343333433333334333443334333333344333334334434433333
-- 011:0000005500005566000556660056666500665656055666560666766606676776
-- 012:5650000066660000666760005666670067666600667667707766767066676700
-- 013:000000000000000000000ccc00cccccd0cccdcdccccdcdddccdcddddcdcddddd
-- 014:0000000000000000ccd00000cdcdc000dcdcdc00dddddde0ddddded0ddddede0
-- 016:6566556677677676377633373333333333333343334333333333433343333333
-- 017:a0ab00a09baaabaa9989a9ab9999999999899989999999999899989999999999
-- 018:a00000009b000000aaa000009aab00009a8abb00999aaaa0989aa8b0999999aa
-- 019:0000000600000056000000670000006300000667000000570000066300000773
-- 020:6000000065000000760000006600000075000000360000003760000037750000
-- 021:6566553377677333677633336333333333333343334333333333433343333333
-- 022:3355665633377677333367763333333634333333333334333334333333333334
-- 023:606666060099990000999900009009000090090000900900009009000ff0ff00
-- 027:0067673400777003000000030000000300000003000000330000033400003444
-- 028:6676700046670000407000004470000044000000440000004340000034440000
-- 029:ccdddddd0dddeded00000eee0000000000000000000000000000000000000000
-- 030:dddedee0ededee00eeee00000000000000000000000000000000000000000000
-- 032:0000000000000000000000000002000002060020006506000005600000057000
-- 033:0000000000000000000000000000000000000000000dde0000eeef00000eff00
-- 034:3333333433344333344fe43333ef333333333333333333433334333343333333
-- 035:6566556677677676377666373377633333377343334673333336433343333333
-- 036:3333333333343333333333333333333333333333333334333333333333433333
-- 037:0000000000000000000000000000000000000000000000000050000006667770
-- 038:00000000000000000000000000dddddd00deeeee00deeeee00deeeee00dddddd
-- 043:0000005500005566000556660056666500662256055622560666766606676776
-- 044:5650000062260000622760005666670067666600667667707766767066666700
-- 045:0000000000000000000000330003000000030000000030000003430000300330
-- 046:0000000000330000034000003400000003000300003340000040300003000300
-- 048:00000000000000000000000000000000000d000000ddd00d00ddee0d0ddeeedd
-- 049:000000000dd00000dddd0000ddeef000deeeff00deeeef00eefeef00effeede0
-- 050:0000000000000000000000000000000000000000000000000000000600000060
-- 051:0033330000ccc330009c9c3000cccc30000cc330666666600066660600666606
-- 052:000333000039c930003ccc30003ccc30003ccc30066666606066660660666606
-- 053:00033300003ccc300039c930003ccc30003ccc30066666606066660660666606
-- 054:eeeeedeeeeeefdeeeeeffdeeddddddddeedeeeeeefdeeeeeffdeeeeedddddddd
-- 055:0000000500000056000000560000006600000007000000030000000300000003
-- 056:5600000066600000667000007700000040000000400000004000000040000000
-- 057:0000000000000000000000000000000300000003000000330000033400003444
-- 058:0000000000000000000000003300000044000000440000004340000034440000
-- 059:0062273400722003000000030000000300000003000000330000033400003444
-- 060:6622700046220000407000004470000044000000440000004340000034440000
-- 061:0000003400000003000000030000000300000003000000330000033400003444
-- 062:3400000044000000400000004400000044000000440000004340000034440000
-- 064:0ddeeedd0deeeede0deedede0dedfede0edefede0defeededdfeeeeedffeeeef
-- 065:efeedee0efeddef0efddeef0fedeeff0fedeeff0feedeff0feeeeeffeeeeefff
-- 067:006666060099990000999900009009000090090000900900009009000ff0ff00
-- 068:006666060099990000999900099009000900090009000900ff0009000000ff00
-- 069:006666060099990000999900009099000090900000909000009ff0000ff00000
-- 070:ccccccccc0000c0cc0000c0cccccccccc0c0000cc0c0000cc0c0000ccccccccc
-- 071:0000000c000000c0000000c0000000c00000000c0000000c0000000c0000000c
-- 072:cc00000000c0000000c000000c000000c0000000c0000000c0000000c0000000
-- 075:000000cc0000cc00000c000000c0000000c000000c0000000c0000000c000000
-- 076:ccc00000000c00000000c00000000c0000000c00000000c0000000c000000c00
-- 080:00000c000c00c000c00000000000000000c000000c0000000000000000000000
-- 081:00003400000034000000340000ddddde00deeeef00efffff0000000000000000
-- 082:0000330000030030003333340033334400343434000343400000000000000000
-- 083:0000033400003340000d340000dee000000eeef00000ef000000f00000000000
-- 086:2222222220000202200002022222222220200002202000022020000222222222
-- 087:0000000200000020000000200000002000000002000000020000000200000002
-- 088:2200000000200000002000000200000020000000200000002000000020000000
-- 089:0000000000000000000000000000000c0000000c000000c000000c000000c000
-- 090:000000000000000000000000cc0000000c0000000c00000000c00000000c0000
-- 091:00c00cc000ccc00c0000000c0000000c0000000c000000c000000c000000c000
-- 092:0000c000000c000000c0000000c000000c0000000c00000000c00000000c0000
-- 096:0000000000000030003003000300000000000000000300000030000000000000
-- 097:000000000ddddde00deeeef00efffff000034000000340000003400000000000
-- 098:0000000000033000003003000333334003333440034343400034340000000000
-- 099:000000000000d000000dee000033eeef03340ef003400f000400000000000000
-- 100:00000000000cc00000c4dd000cd4ddf00cd44df000dddf00000ff00000000000
-- 101:000000000ddd00000dee00000deddd000dedee00000dee00000dee0000000000
-- 102:00ccc0000c0c0c00c00c00c0c00cc0c0c00000c00c000c0000ccc00000000000
-- 104:ccccccccc000000cc000000cc000000cc000000cc000000cc000000ccccccccc
-- 107:0000002200002200000200000020000000200000020000000200000002000000
-- 108:2220000000020000000020000000020000000200000000200000002000000200
-- 112:eeeeedeeeeeefdeeeeeffdeeddddddddeedeeeeeefdeeeeeffdeeeeedddddddd
-- 113:0000033000003344000334440033444003344400333340003333000003300000
-- 114:00cc11000c111110c11cc111c113131111c13113111311130111113000113300
-- 115:00c4c0000cd4dd00cdd4dde0cdd44de0cddddde00dddde0000eee00000000000
-- 116:ccc00000cdd00000cdccc000cdcdd00000cdccc000cdcdd00000cdd00000cdd0
-- 119:000000000000000000000000000000000000ccc00000cc000000c0c00000000c
-- 120:cc0000ccc000000c00000000000000000000000000000000c000000ccc0000cc
-- 121:000000cc00000cc00000000000cc0cc00cc0cc000000000000cc00000cc00000
-- 122:00000000000c0000000c0000000c0000c00c00c00c0c0c0000ccc000000c0000
-- 123:0020022000222002000000020000000200000002000000200000020000002000
-- 124:0000200000020000002000000020000002000000020000000020000000020000
-- 128:eeeede00eeeede00dddddd00edeeee00edeeee00dddddd000000000000000000
-- 129:0003300000334400033444003333400033330000033000000000000000000000
-- 130:00cc00000c111000c1c11300c113130001113000003300000000000000000000
-- 131:00cc00000c4dd000cd4ddf00cd44df000dddf00000ff00000000000000000000
-- 132:0ddd00000dee00000deddd000dedee00000dee00000dee000000000000000000
-- 135:0000000000000000000000000000000000002220000022000000202000000002
-- 136:2200002220000002000000000000000000000000000000002000000222000022
-- 137:0000002200000220000000000022022002202200000000000022000002200000
-- 138:0000000000020000000200000002000020020020020202000022200000020000
-- 144:000000cc00000cc00000000000cc0cc00cc0cc000000000000cc00000cc00000
-- 145:000000000cccccc00cccccc00cccccc0000cc000000cc000000cc00000000000
-- 146:00000000000cc00000c00c000cccccc00cccccc00cccccc000cccc0000000000
-- 147:000000000000c000000ccc0000cccccc0ccc0cc00cc00c000c00000000000000
-- 148:000000000ccc00000ccc00000ccccc000ccccc00000ccc00000ccc0000000000
-- 160:0000002200000220000000000022022002202200000000000022000002200000
-- 161:0000000002222220022222200222222000022000000220000002200000000000
-- 162:0000000000022000002002000222222002222220022222200022220000000000
-- 163:0000000000002000000222000022222202220220022002000200000000000000
-- 164:0000000002220000022200000222220002222200000222000002220000000000
-- 204:000000000000cccc000cdddd00cddddd0cdddddd0cdddddd0cdddddd0cdddddd
-- 205:00000000cccc00ccddddecccdddcdddddddddddddceddddddddddddddddddddd
-- 206:00000000ccccccccdddddddddddddddddddddddddddddddddddddddddddddddd
-- 207:00000000cccc0000ddddd000dddddd00dddddde0dddddde0dddddde0dddddde0
-- 216:ddddddddddddddddddeedddddeddddefdfdddfffdeddffedddefeddddddddddd
-- 217:ddddddddddddddddddddddddffffffffffffffffdddddddddddddddddddddddd
-- 218:ddddddddddddddddddddeeddfeddddedfffdddfddeffddeddddefedddddddddd
-- 220:0cdddddd0cdddddd0cdddddd00eddddd00cddddd0cdddddd0cdddddd0cdddddd
-- 221:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
-- 222:ddddddddddddddddddddddddddddddddddddddedddddeecddddddcdddddddddd
-- 223:dddddde0dddddde0dddddde0ddddde00ddddde00dddddee0dddddd00dddddde0
-- 224:00000000000000000000000000000000000c000000c0c00c00c00c0c0c0000c0
-- 225:000000000cc00000c00c0000c000c000c0000c0000000c0000000c00000000c0
-- 236:0cdddddd0cdddddd0cdddddd0cdddddd0cdddddd0cdddddd0cdddddd0cdddddd
-- 237:dddddddddddddddddddddddddddddddddddeddddddddcddddddddddddddddddd
-- 238:dddddddddddddddddcdddddddddddddddddddddddddddddddddddddddddddddd
-- 239:dddddde0dddddde0dddddde0dddddde0dddddde0dddddde0dddddde0dddddde0
-- 240:0c0000000c0000000c0000000c0000000c0000000c000000c0000000c0000000
-- 241:000000c0000000c0000000c0000000c0000000c0000000c00000000c0000000c
-- 252:0cdddddd0cdddddd0cdddddd0cdddddd00dddddd000ddddd0000eeee00000000
-- 253:ddddddddddddddddddddddddddddddddddddddddddddeeeeeeee00ee00000000
-- 254:ddddddddddddddddddddddddddddddddddddddddddddddddeeeeeeee00000000
-- 255:dddddde0dddddde0dddddde0dddddde0ddddde00dddde000eeee000000000000
-- </TILES>

-- <MAP>
-- 000:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 001:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 002:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003142000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 003:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 004:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 005:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003142000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 006:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003142000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 007:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003142000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 008:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000315110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 009:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005202000000000000000000311010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 010:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003132014100000e0000000031518042000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 011:0000000000000000000000000000000000003101410000000000000e1e00000000000000000000000000000031511010614100000000003151101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 012:000000000000003101324100000000b400315110324100000000000f1f00000000000000000000000000003151424210106132320101015110221010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 013:000000000000315110106101410000023151102280610141000031010101410000000000000000000000313210101010101010101010421042104210000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 014:00000000003151104242101061010150501010421042106101015110108061010141000000b400000031514210101042101010221010421010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 015:000000003151101022101042104210801080421042101042101010421010101010614102000000003151101010102210424242421042424242424210000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 016:010101015142421010101042104280102210101010421010421010421010221010106101015050015110421010101010101010104210101010421010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 032:210000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 040:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 041:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 042:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 043:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 044:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 045:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 046:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e00003110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 047:000000000000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000023110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 048:000000000000000000000000000000000000000000000000000000000000000e000031320141000000b400b400b400b400b400000031010101325110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 049:000000000000000000000000000000000000000000000000000000000000000000315110106101014100000000000000000000310151101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 050:000000000000000000000000000000000000000000000000000000000000010101511010101010106101500101505050010101511010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 066:000000000000000000000000000000000000000000000000000000000000210000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </MAP>

-- <WAVES>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- </WAVES>

-- <SFX>
-- 000:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000304000000000
-- </SFX>

-- <FLAGS>
-- 000:00601060406000006040004040000000601010000060600040400040400000000000606060002040400000404040400040400000000060404000004040404000404000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </FLAGS>

-- <PALETTE>
-- 000:1a1c2cceb25db13e537559573c2c24a7f07038b7640c483829366f3b5dc941a6f6b6c6f6f4f4f494b0c2566c86333c57
-- </PALETTE>

