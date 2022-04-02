-- title:  dyke march
-- author: lena schimmel
-- desc:   a game for ld50
-- script: lua

t=0
px=12
tx=12
pf=0
tb=0
sx=0
sb = 30

levelwidth = 60
levelheight = 17

function OVR()
  map(0,0,levelwidth,levelheight,-sx,0,0)
end

function TIC()
  cls(11)
  map(0,17,levelwidth,levelheight,-sx,0,0)
  x,y,l = mouse()
  mx = math.floor((x+sx) / 8)
  my = math.floor(y / 8)
  
  if x < sb then
    sv = sb - x
    sx = math.max(sx - sv / 40, 0)
  end
  if x > (240 - sb) then
    sv = x - (240 - sb)
    sx = math.min(sx + sv / 40, (levelwidth * 8) - 240)
  end
  print(sx)

  sp = 6
  if isvalidblockpos(mx,my) then
    sp = 5
    if l then
      tx = mx
        ty = my
        tb=1
        --mset(mx,my,3)
      end
  end
	spr(sp,mx*8-sx,my*8,0)
	t=t+1
	
	for py = 0,18,1 do
    if isblock(px,py) then
      spr(7,px*8-sx,(py-2)*8,0, 1, pf, 0, 1, 2)
      break
    end	
	end
	
	if t % 20 == 0 then
	  if px < tx - 1 then
		  px = px + 1
				pf = 1
		elseif px > tx + 1 then
		  px = px - 1
			pf = 0
		elseif tb ~= 0 then
		  tb = 0
			setblock(tx,ty)
		end
	end
	
	if t % 120 == 0 then
    addwater()
		t = 0
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

-- <TILES>
-- 001:3333333434333333333433333333333333333343334333333333433343333333
-- 002:9999999999999989998999999999999999999989999999999899989999999999
-- 003:eeeeedeeeeeefdeeeeeffdeeddddddddeedeeeeeefdeeeeeffdeeeeedddddddd
-- 004:ccccc000cccc0000ccc00000cc0c0000c000c00000000c00000000c00000000c
-- 005:cc0000ccc000000c00000000000000000000000000000000c000000ccc0000cc
-- 006:2200002220000002000000000000000000000000000000002000000222000022
-- 007:0003330000ccc330009c9c3000cccc00000cc000066666606066660660666606
-- 008:0000005500005566000556660056666500665656055666560666766606676776
-- 009:5650000066660000666760005666670067666600667667707766767066676700
-- 010:000000000000000000000ccc00cccccd0cccdcdccccdcdddccdcddddcdcddddd
-- 011:0000000000000000ccd00000cdcdc000dcdcdc00dddddde0ddddded0ddddede0
-- 012:dddddee0ddddddd0eddddddc0ddddddd0cdddddccdcdddddccdcddddcdcddddd
-- 016:6566556677677676377633373333333333333343334333333333433343333333
-- 017:a0ab00a09baaabaa9989a9ab9999999999899989999999999899989999999999
-- 018:a00000009b000000aaa000009aab00009a8abb00999aaaa0989aa8b0999999aa
-- 019:0000000600000056000000670000006300000667000000570000066300000773
-- 020:6000000065000000760000006600000075000000360000003760000037750000
-- 021:6566553377677333677633336333333333333343334333333333433343333333
-- 022:3355665633377677333367763333333634333333333334333334333333333334
-- 023:0606660600099900000999000009090000090900000909000009090000ffff00
-- 024:0067673400777003000000030000000300000003000000330000033400003444
-- 025:6676700046670000407000004470000044000000440000004340000034440000
-- 026:ccdddddd0dddeded00000eee0000000000000000000000000000000000000000
-- 027:dddedee0ededee00eeee00000000000000000000000000000000000000000000
-- 032:0000000000000000000000000002000002060020006506000005600000057000
-- 033:0000000000000000000000000000000000000000000dde0000eeef00000eff00
-- 034:3333333433344333344fe43333ef333333333333333333433334333343333333
-- 035:6566556677677676377666373377633333377343334673333336433343333333
-- 036:3333333333343333333333333333333333333333333334333333333333433333
-- 037:0000000000000000000000000000000000000000000000000050000006667770
-- 038:65665566776476763773473737333433343333433343343434334f334f333333
-- </TILES>

-- <MAP>
-- 002:0000000000000000000000000000a0b000000000000000000000000000000000000000000000000000000000000000000000000000000000a0b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 003:0000000000000000000000000000a1c0b000000000000000000000000000000000a0b0000000000000000000000000000000000000000000a1b10000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 004:00000000a0b0000000000000000000a1b1000000000000a0b00000000000000000a1c0b0000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 005:00000000a1b10000000000000000000000000000000000a1b1000000000000000000a1b1000000000000000000000000000000000000000000003101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 006:000000000000000000000000000000000000000000000000000000000000000000000000000000000000a0b000000000000000000000000000003110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 007:000000000000000000000000000000000000a0b000000000000000000000000000000000000000000000a1b100000000000000000000000000003142000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 008:000000000000000000000000000000000000a1b100000000000000000000000000000000000000000000000000000000000000000000000000315110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 009:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005202000000000000000000311010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 010:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000313201410000000000000031511042000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 011:000000000000000052000000000000000000310141000000000000809000000000000000000000000000000031511010614112809080903151101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 012:000000000000003101324100008090000031511032410000000000819100000000000000000000000000003151424210106132326262015110221010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 013:000000000000315110106101418191023151102210610141521231016201418090000000000000000000313210101010101010101010421042104210000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 014:000000000031511042421010616262013210104210421061010151101010610162410000809080900031514210101042101010221010421010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 015:008090123151101022101042104210101010421042101042101010421010101010614102819181913151101010102210424242421042424242424210000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 016:010162015142421010101042104210102210101010421010421010421010221010106101623232015110421010101010101010104210101010421010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
-- 000:1a1c2c5d275db13e537559573c2c24a7f07038b7640c483829366f3b5dc941a6f6b6c6f6f4f4f494b0c2566c86333c57
-- </PALETTE>

