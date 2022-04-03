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
to=0 -- tool (0=walk, 1=build, 2=collect, 3=cut, 4=card)
wo = false -- working, time passing, accept no input during this

pf=0 -- player flip (walking direction)
sx=0 -- scroll x in pixel
sb = 30 -- scroll sensitive border
re = {5, 0, 0} -- ressources (stone, wood, score)
wt = 120 -- water tics
pt = 10 -- player tics

levelwidth = 60
levelheight = 17

re_names={"stone", "wood", "score", "time"}
re_symbols={"#", "/", "$", "*"}

objecttypes = {
  {
    name="dyke",
    cost={1,0,0,60},
    desc="stops water and you can walk on it",
    sx=1,
    sy=1,
    sprites={4,38,54,54},
    isblock=true
  }
}

objects = {}

function createobject(type,tx,ty)
  object = {
    type = type,
    x = tx,
    y = ty,
    state = 1
  }
  table.insert(objects, object)
  return object
end

function drawobject(o)
  ty = o.type
  sp = ty.sprites[o.state]
  spr(sp,o.x*8-sx,o.y*8,0, 1, 0, 0, ty.sx, ty.sy) 
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


function OVR()
  map(0,0,levelwidth,levelheight,-sx,0,0)

  x,y,l = mouse()
  my = y // 8

  -- show resources
  te = string.format("%2d# %2d/ %4d$",re[1],re[2],re[3])
  prints(te, 8, 8, 12)

  -- show actions
  prints("Action:", 16*6, 8, 12)
  for i=0,4 do
    spr(96 + i, 144 + 12*i, 8, 0)
    if to==i then
      spr(104, 144 + 12*i, 8, 0)
    end
  end

  ct = "" --center text
  -- draw cursor
  sp = 119
  if my > 2 then -- lower screen part
    if wo then
      sp = 102
    else
      if to == 0 then -- walk
        sp = 160 + to -- disabled
        if isempty(mx,my) then
          for ly=my+1,levelheight do
            if not isempty(mx,ly) then
              if isblock(mx, ly) then
                if ly - 1 ~= my then
                  spr(122,mx*8-sx,ly*8-8,0)
                end
                sp = sp - 16 -- enable
                ct = "Walk here: 4*"
                if l then
                  tx = mx
                  wo = true
                end
              else
                ct = "Not walkable"
              end
              break
            end
          end
        else
          ct = "Not walkable"
        end
      end
      if to == 1 then
        ty = objecttypes[1]
        sp = 136
        mis = canpay(ty.cost)
        if mis > 0 then
          ct = "Not enough " .. re_symbols[mis] .. " to build " .. ty.name
        elseif not isvalidblockpos(mx,my) then
          ct = "Cant build " .. ty.name .. " here"
        else
          sp = 120
          if px < mx then
            ptx = mx - 1
          elseif px > mx + ty.sx - 1 then
            ptx = mx + ty.sx
          else
            ptx = mx
          end
          ct = "Build " .. ty.name .. " here: " .. coststring(ty.cost, math.abs(px - ptx) * pt)
          if l then
            tx = ptx
            bx = mx
            by = my
            pay(ty.cost)
            wo = true
            tb = createobject(ty,mx,my)
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
          if mxc > i*4 - 4 and mxc < i*4 then
            ct =  re[i] .. " " .. re_names[i]
          end
        end
        for i=0,4 do
          if mxc == 24 + 2*i then
            sp = 120
            texts = {"walk", "build dyke", "collect", "cut", "play card"}
            ct = texts[i+1]
            if l then
              to = i
            end
          end
        end
      end
    end
    spr(sp,mxc*6,my*8,0)
  end
  printc(ct, 120, 0, 12)
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

function coststring(cost, extratime)
  str = ""
  for i = 1,4 do
    co = cost[i]
    if i == 4 then
      co = co + extratime
      co = co / wt
    end
    if co > 0 then
      if string.len(str) > 0 then
        str = str .. ", "
      end
      str = str .. cost[i] .. " " .. re_symbols[i]
    end
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

  -- update
  if wo then
    t=t+1
    if t % pt == 0 then
      if px < tx then
        px = px + 1
          pf = 1
      elseif px > tx then
        px = px - 1
        pf = 0
      else -- reached target
        if to == 0 then
          wo = false
        end
        if to == 1 and tb ~= nil then
          tb.state = 3
          if tb.type.isblock then
            mset(tb.x,tb.y,3)
          end
          tb = nil
          wo = false
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
  map(0,17,levelwidth,levelheight,-sx,0,0)

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
  spr(body,px*8-sx,(py-1)*8,0, 1, pfb) -- body
  spr(legs,px*8-sx,(py-0)*8,0, 1, pf) -- legs
  if wo and to > 0 and to < 4 then
    dx = px - 1 + 2 * pf
    spr(50,dx*8-sx,(py-1)*8,0, 1, pf) -- arm
    spr(to+80,dx*8-sx,(py-0)*8,0, 1, pf) -- tool
  end
end

function yabovefloor(x)
  for y = 0,18,1 do
    if isblock(x,y) then
      return y - 1
    end	
	end
end

function isvalidblockpos(x,y)
	return isempty(x,y) and isblock(x-1,y+1) and isblock(x,y+1) and isblock(x+1,y+1)
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
  
  if isempty(x+1, y) then
    while isempty(x+1,y+1) do
      y = y + 1
    end
  	setwater(x+1, y)
   return
  end
  
  while x > 0 and isempty(x-1,y) do
    x = x - 1
  end
  
  if isempty(x,y) then
    while isempty(x+1,y+1) do
      y = y + 1
    end
    setwater(x+1, y)
  else
    y = y - 1
    while x > 0 and isempty(x-1,y) do
      x = x - 1
    end
    setwater(x,y)
  end
end

function setwater(x,y)
  if isblock(x+1,y) then
    mset(x, y+levelheight, 17)
  else
    mset(x, y+levelheight, 18)
  end
  if iswater(x-1,y) then
    mset(x-1, y+levelheight, 17)
  end
  if iswater(x,y+1) then
    mset(x, y+1+levelheight, 2)
  end
end

function iswater(x,y)
  return fget(mget(x,y+levelheight),0)
end

function isblock(x,y)
  return fget(mget(x,y),1) or fget(mget(x,y+levelheight),1)
end

function setblock(x,y)
  return mset(x,y+levelheight,3)
end

function isempty(x,y)
  return fget(mget(x,y),2) and fget(mget(x,y+levelheight),2) and not iswater(x,y)
end

--Prints text where x is the center of text.
function printc(s,x,y,c)
  local w=print(s,0,-8)
  prints(s,x-(w/2//6*6),y,c or 15, true)
end

--Prints text, replaces some symbols with sprites
function prints(s,x,y,c)
  print(s:gsub("$"," "):gsub("/"," "):gsub("#"," "):gsub("*"," "),x,y+1,c or 15, true)
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

-- <TILES>
-- 001:3333333434333333333433333333333333333343334333333333433343333333
-- 002:9999999999999989998999999999999999999989999999999899989999999999
-- 003:eeeeedeeeeeefdeeeeeffdeeddddddddeedeeeeeefdeeeeeffdeeeeedddddddd
-- 004:0a0a0a0aa00000000000000aa00000000000000aa00000000000000aa0a0a0a0
-- 005:65665566776476763773473737333433343333433343343434334f334f333333
-- 007:0003330000ccc330009c9c3000cccc30000cc330066666606066660660666606
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
-- 048:00000000000000000000000000000000000d000000ddd00d00ddee0d0ddeeedd
-- 049:000000000dd00000dddd0000ddeef000deeeff00deeeef00eefeef00effeede0
-- 050:0000000000000000000000000000000000000000000000000000000600000060
-- 051:0003330000ccc330009c9c3000cccc30000cc330666666600066660600666606
-- 052:000333000039c930003ccc30003ccc30003ccc30066666606066660660666606
-- 053:00033300003ccc300039c930003ccc30003ccc30066666606066660660666606
-- 054:eeeeedeeeeeefdeeeeeffdeeddddddddeedeeeeeefdeeeeeffdeeeeedddddddd
-- 055:0000000500000056000000560000006600000007000000030000000300000003
-- 056:5600000066600000667000007700000040000000400000004000000040000000
-- 057:0000000000000000000000000000000300000003000000330000033400003444
-- 058:0000000000000000000000003300000044000000440000004340000034440000
-- 059:0062273400722003000000030000000300000003000000330000033400003444
-- 060:6622700046220000407000004470000044000000440000004340000034440000
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
-- 100:000000000ccc00000cdd00000cdccc000cdcdd00000cdd00000cdd0000000000
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
-- 132:0ccc00000cdd00000cdccc000cdcdd00000cdd00000cdd000000000000000000
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
-- </TILES>

-- <MAP>
-- 004:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 005:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 006:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 007:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003142000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 008:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000315110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 009:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005202000000000000000000311010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 010:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000313201410000000000000031511042000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 011:000000000000000000000000000000000000310141000000000000000000000000000000000000000000000031511010614112000000003151101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 012:000000000000003101324100000000000031511032410000000000000000000000000000000000000000003151424210106132320101015110221010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 013:000000000000315110106101410000023151102210610141000031010101410000000000000000000000313210101010101010101010421042104210000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 014:000000000031511042421010610101013210104210421061010151101010610101410000000000000031514210101042101010221010421010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 015:000000123151101022101042104210101010421042101042101010421010101010614102000000003151101010102210424242421042424242424210000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 016:010101015142421010101042104210102210101010421010421010421010221010106101013232015110421010101010101010104210101010421010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 032:210000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
-- 000:40201020000000004040000000000000201010404020200040400000000000004040202000402000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </FLAGS>

-- <PALETTE>
-- 000:1a1c2cceb25db13e537559573c2c24a7f07038b7640c483829366f3b5dc941a6f6b6c6f6f4f4f494b0c2566c86333c57
-- </PALETTE>

