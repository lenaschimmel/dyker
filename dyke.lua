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
ttw = 0

levelindex = 1
selectedcard = 0
buildingcard = nil
buildingtype = nil
clicklock = false

cuttimemulti = 1
walktimemulti = 1
appletimemulti = 1
wooltimemulti = 1

function start() 
  loadlevel(1)
end

function lmget(x,y)
  return mget(x+levelx, y+levely)
end

function lmset(x,y,t)
  mset(x+levelx, y+levely, t)
end

globalstate = "title" -- title, levelstart, play, levelend, gamewon, restart

re_names={"stone", "wood", "coins", "time", "cards"}
re_symbols={"#", "/", "$", "*", "@"}
to_names={"walk", "build dyke", "collect", "cut", "wait", "play card"}

levels = {
  {
    name = "Introduction",
    introtext = "Welcome to the island! Have a nice time, make yourself at home... but not too much. There's a flood wave coming, see if you can earn 70$  for a ticket to flee!",
    outrotext = "Well, that wasn't too hard, right? Let's try another island.",
    x = 30,
    y = 34,
    w = 30,
    m = 70,
    re = {15, 30, 30, 0}
  },
  {
    name = "Level two",
    introtext = "Look, there's a lot more space here. Space to plant trees or even herd some sheep. And more space for the flood wave, of course. This time, you need 100$  to get away from here.",
    outrotext = "Time for a new challenge, right?",
    x = 0,
    y = 0,
    w = 60,
    m = 100,
    re = {5, 5, 5, 3}
  },
  {
    name = "Level three",
    introtext = "You made it! Your own little house, on a beautiful island, packed with books. If you aint got nothing else to do, you can study them to find more cards @ ! Let's hope those books don't get wet...",
    outrotext = "Didn't have much look with those books, right? But don't be disgruntled - you survided, and so has the knowlege inside your head!",
    x = 87,
    y = 0,
    w = 53,
    m = 130,
    re = {10, 10, 10, 5}
  },
}

objecttypes = {
  dyke={
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
  rock={
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
  chest={
    name="chest",
    cost={0,0,0,0},
    desc="there is a card inside",
    sx=1,
    sy=1,
    sprites={194,194,194,195,195},
    isblock=false,
    collect = {
      verb = "open",
      re = 1,
      gain = {0,0,0,0,1},
      time = 30,
      effect = function(o)
        destroyobject(o)
      end
    },
    draw = function(o)
      x = o.x*8-sx
      y = o.y*8
      if o.collect.re > 0 then
        spr(194,x,y,0)
      else
        spr(195,x,y,0)
      end
    end 
  },
  tree={
    name="tree",
    cost={0,0,0,180},
    desc="you can collect apples from it, or cut it for wood.",
    sx=2,
    sy=2,
    sprites={75,39,11,41,45},
    isblock=false,
    spoutline=75,
    spoutlinered=107,
    cut = {
      verb = "cut",
      re = 0,
      gain = {0,5,0,0},
      time = 250
    },
    collect = {
      verb = "pick",
      re = 0,
      gain = {0,0,2,0},
      time = 10
    },
    create = function(o)
      o.ttg = 300
      o.tta = 400 * appletimemulti
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
          o.tta = 200 * appletimemulti
          if o.collect.re < 4 then
            stopwait()
          end
          o.collect.re = math.min(4,o.collect.re+1)
        end
      end

      -- die when it is cut down
      if o.state == 3 and o.cut.re == 0 then
        o.state = 4
      end

      -- die when it touches water and is not already cut down
      if o.state < 4 then
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
  well={
    name="well",
    cost={5,0,0,300},
    desc="your plants get their fruit quicker",
    sx=1,
    sy=2,
    sprites={151,150,149,149,149},
    isblock=false,
    spoutline=151,
    spoutlinered=152,
    create = function(o)
      appletimemulti = appletimemulti * 0.7
    end,
  },
  sheep={
    name="sheep",
    cost={0,5,10,30},
    desc="If gives you wool or meat.",
    sx=1,
    sy=1,
    sprites={192,176,177,177,180},
    isblock=false,
    spoutline=192,
    spoutlinered=193,
    cut = {
      verb = "butcher",
      re = 0,
      gain = {0,0,25,0},
      time = 200,
      effect = function(o)
        destroyobject(o)
        o.state = 5
        o.butchered = true
      end
    },
    collect = {
      verb = "shear",
      re = 0,
      gain = {0,0,5,0},
      time = 150
    },
    create = function(o)
      o.ttg = 500
      o.tta = 600 * wooltimemulti
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
          o.tta = 600 * wooltimemulti
          if o.collect.re < 2 then
            stopwait()
          end
          o.collect.re = math.min(2,o.collect.re+1)
        end
      end

      if o.state < 4 then
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
      x = o.x*8-sx
      y = o.y*8
      sp = o.type.sprites[o.state]
      if o.state == 5 then
        if o.butchered then
          sp = 0
        end
      end
      if o.state == 3 then
        if o.collect.re == 0 then
          sp = 177
        elseif o.collect.re == 1 then
          sp = 178
        elseif o.collect.re == 2 then
          sp = 179
        end
      end
      spr(sp,x,y,0)
    end 
  },
  mine={
    name="mine",
    cost={2,5,0,300},
    desc="mine an unlimited supply of stones",
    sx=2,
    sy=2,
    sprites={155,155,155,155,155},
    isblock=false,
    spoutline=181,
    spoutlinered=183,
    collect = {
      verb = "mine",
      re = 999,
      gain = {1,0,0,0},
      time = 150
    },
  },
  house={
    name="house",
    cost={2,5,5,300},
    desc="study at home to gain knowledge, aka cards",
    sx=2,
    sy=2,
    sprites={153,153,153,153,153},
    isblock=false,
    spoutline=153,
    spoutlinered=153,
    collect = {
      verb = "study",
      re = 10,
      gain = {0,0,0,0,1},
      time = 240
    },
  }
  
}


objects = {}
cards = {}
permanents = {}

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

  cuttimemulti = 1
  walktimemulti = 1
  appletimemulti = 1
  wooltimemulti = 1

  objects = {}
  permanents = {}

  for x=0,levelwidth do
    for y=0,levelheight do
      type = nil
      if lmget(x,y) == 224 then
        type = objecttypes['rock']
      end
      if lmget(x,y) == 75 then
        type = objecttypes['tree']
      end
      if lmget(x,y) == 192 then
        type = objecttypes['sheep']
      end
      if lmget(x,y) == 181 then
        type = objecttypes['mine']
      end
      if lmget(x,y) == 153 then
        type = objecttypes['house']
      end
      if lmget(x,y) == 194 then
        type = objecttypes['chest']
      end
      if type then
        o = createobject(type,x,y)
      end
    end
  end
end

function OVR()
  x,y,l = mouse()
  if globalstate == "title" then
    map(120,34,30,levelheight,0,0,0)
    prints("Click to start the game", 12*8, 8*8, 12)
    print("A game by @LenaSchimmel", 2*8, 14*8, 12, false, 1, false)
    print("Made in 72 hours for Ludum Dare 50", 2*8, 15*8, 12, false, 1, true)
    
    if l then
      globalstate = "levelstart"
    end
    
    return
  end

  if globalstate == "gamewon" then
    map(120,34,30,levelheight,0,0,0)
    prints("Thank you for playing!", 12*8, 8*8, 12)
    print("You won all levels of Dyker", 2*8, 14*8, 12, false, 1, false)
    print("Come back later to see if there is a post-jam version.", 2*8, 15*8, 12, false, 1, true)
    
    if l then
      globalstate = "levelstart"
    end
    
    return
  end

  if globalstate == "levelstart" or globalstate == "play" or globalstate == "levelend" or globalstate == "restart" then
    map(levelx,levely,levelwidth,levelheight,-sx,0,0)
    
    if not l then
      clicklock = false
    end
    my = y // 8

    -- show resources
    te = string.format("%2d# %2d/ %4d$",re[1],re[2],re[3])
    prints(te, 6, 8, 12)
  end

  ct = "" --center text
  -- draw cursor, handle potential actions
  local sp = 119

  if globalstate == "play" then
    -- show actions
    prints("Action:", 16*6, 8, 12)
    for i=1,6 do
      spr(95 + i, 132 + 12*i, 8, 0)
      if to==i then
        spr(104, 132 + 12*i, 8, 0)
      end
    end
    prints(""..#handcards, 212, 8, 14)

    if x >= 228 and y < 8 then
      myspr(228, 29, 0)
      ct = "Restart level"
      if l then
        globalstate = "restart"
      end
    else
      myspr(227, 29, 0)
    end

    if to==6 then
      sp = 119
      local ci, bu = paintcards(x/8, y/8)
      if bu then
        card = handcards[ci]
        mis = canpay(card.cost)
        if mis > 0 then
          sp = 164
          ct = "Not enough " .. re_symbols[mis] .. " to play '" .. card.title .. "'"
          paintcards(0,0,true,2)
        else
          sp = 148
          ct = "Play the card '" .. card.title .. "'"
          paintcards(0,0,true,5)
          if l and not clicklock then
            if not card.buildingtype then
              pay(card.cost) -- buildings are paid later
            end
            selectedcard = 0
            trace("Remove card " .. ci)
            table.remove(handcards, ci)
            card.y = 14
            if card.effect then
              card.effect()
            elseif card.gain then
              earn(card.gain)
            end

            if card.ispermanent then
              table.insert(permanents, card)
            end

            if card.buildingtype then
              buildingcard = card
              buildingtype = card.buildingtype
              clicklock = true
              to = 2
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
        clicklock = true
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
              if l and not clicklock then
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
          ty = buildingtype or objecttypes['dyke']

          wantscancel = false
          if ty == objecttypes['dyke'] then
            validpos = isvaliddykepos(mx,my)
          else
            printc("Place " .. ty.name, 110, 8*3)
            printc("Click here to cancel", 110, 8*4)
            if my >= 3 and my <= 4 then
              wantscancel = true
            end
            validpos = true
            for xx = 1, ty.sx do
              for yy = 1, ty.sy do
                if not isbuildable(xx+mx-1, yy+my-1) then
                  validpos = false
                end
              end
              if not isblock(xx+mx-1, my+ty.sy) then
                validpos = false
              end
            end
          end
          mis = canpay(ty.cost)
          if wantscancel then
            ct = "That card will go back to your hand"
            if l then
              buildingtype = nil
              table.insert(handcards, buildingcard)
              buildingcard = nil
              to = 0
            end
          elseif mis > 0 then
            ct = "Not enough " .. re_symbols[mis] .. " to build " .. ty.name
          elseif not validpos then
            ct = "Cant build " .. ty.name .. " here"
            sp = ty.spoutlinered -- no real cursor, we draw the building outline
          else
            sp = ty.spoutline -- no real cursor, we draw the building outline
            left = mx
            right = mx + ty.sx - 1
            ptx = workpoint(left, right)
            if isreachable(ptx, my) then
              ct = "Build " .. ty.name .. " here: " .. coststring(ty.cost, walktimetox(ptx))
              if l and not clicklock then
                buildingtype = nil
                buildingcard = nil
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
                    actiontime = action.time
                    if action.verb == "cut" then
                      actiontime = actiontime * cuttimemulti
                    end
                    ct = action.verb .. " " .. ty.name .. " to get " .. coststring(action.gain) .. ": " .. timestring(walktimetox(ptx) + actiontime) .. " ("..releft.."x left)"
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
                -- return the card if the player currently builds a card building
                if to == 2 and i ~= 2 and buildingcard then
                  buildingtype = nil
                  table.insert(handcards, buildingcard)
                  buildingcard = nil
                end

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
  end

  if globalstate == "levelstart" or globalstate == "levelend" or globalstate == "restart" then
    paintframe(3,2,24,13,777)

    color = 12
    if x >= 8*4 and x <= 8*26 and y >= 100 and y <= 110 then
      color = 5
    end

    if globalstate == "levelstart" then
      printc(levels[levelindex].name, 120,29, 15)
      textrect(levels[levelindex].introtext, 42, 55, 200 - 42)
      printc("Click here to start the level", 120,100, color)
      if color == 5 and l and clicklock == false then
        globalstate = "play"
        clicklock = true
      end
    end

    if globalstate == "levelend" then
      printc("You won the level!", 120,29, 15)
      textrect(levels[levelindex].outrotext, 42, 55, 200 - 42)
      printc("Click here for the next level", 120,100, color)
      if color == 5 and l and clicklock == false then
        clicklock = true
        levelindex = levelindex + 1
        if #levels < levelindex then
          globalstate = "gamewon"
        else
          loadlevel(levelindex)
          globalstate = "levelstart"
        end
      end
    end

    if globalstate == "restart" then
      printc("Restart this level?", 120,29, 15)
      textrect("If you think you can't win anymore - or it would be really tedious to win after you had a bad start - you may restart this level.", 42, 55, 200 - 42)
      
      
      color2 = 12
      if x >= 8*4 and x <= 8*26 and y >= 88 and y <= 98 then
        color2 = 5
      end

      printc("Click here to restart", 120,88, color2)
      printc("Click here to contiune playing", 120,100, color)
      if l and clicklock == false then
        clicklock = true
        if color == 5 then -- continue
          globalstate = "play"
        end
        if color2 == 5 then -- restart
          sync(4)
          loadlevel(levelindex)
          globalstate = "levelstart"
        end
      end
    end
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
  return  math.abs(px - x) * pt * walktimemulti
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

  if gain[5] then
    for i = 1,gain[5] do
      drawrandomcard()
    end
  end

  if re[3] >= tm then
    trace("Level won")
    globalstate = "levelend"
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

function TIC()
  if globalstate == "title" then
    cls(10)
  else
    cls(11)
  end

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
      ttw = ttw - 1
      if ttw <= 0 then
        ttw = pt * walktimemulti
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
            if tb.type.name ~= "tree" and tb.type.name ~= "sheep" then
              tb.state = 3
            end
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
            if to == 4 then
              tl = tl * cuttimemulti
            end
          end
          
          tl = tl - 1
          if tl <= 0 then -- finished doing it
            if to == 3 then
              tb.collect.re = tb.collect.re - 1
            end
            if to == 4 then
              tb.cut.re = tb.cut.re - 1
              if tb.cut.re == 0 then -- todo should this be an effect?
                destroyobject(tb)
              end
            end
            earn(action.gain)
            if action.effect then
              action.effect(tb)
            end
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

  if globalstate ~= "title" then
    map(levelx,levely+17,levelwidth,levelheight,-sx,0,0)
  end

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
    if (to == 2 or to == 4) and t % 30 < 15 and px == tx then
      spr(to+79,dx*8-sx,(py-1)*8,0, 1, pf, 1) -- tool
    else
      spr(to+79,dx*8-sx,(py-0)*8,0, 1, pf) -- tool
    end
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

  if x >= px then
   px = x + 1
   py = yabovefloor(px)
  end  
  if x >= tx then
    tx = x + 1
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

function paintframe(x,y,w,h,r)
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
end

function paintcard(x,y,w,h,title,text,cost,r,onlybutton, buttoncolor)
  if not onlybutton then
    paintframe(x,y,w,h,r)

    print(title, x*8+6, y*8 + 6, 15)
    prints(coststring(cost, 0, true), x*8+6, (y+2)*8)
  end
  paintcardbutton(x*8+w*4, (y+h-1)*8 - 6, buttoncolor or 9)

  if y > 13 or onlybutton then
    return
  end

  textrect(text, x*8+6, (y+4)*8+6, w*8 - 12)
  
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
      title="Book",
      text="Read a book. Draw 3 cards.",
      cost = {0,0,25,0},
      r=234,
      effect = function()
        for i=1,3 do
          drawrandomcard()
        end
      end,
    },
    {
      title="Boots",
      text="With these boots, you can walk 20% faster.",
      cost = {0,3,3,0},
      ispermanent = true,
      effect = function()
        walktimemulti = walktimemulti * 0.8
      end,
      r=235,
    },
    {
      title="Axe",
      text="With this improved axe, you can cut treed and rocks 20% faster.",
      cost = {1,3,5,0},
      ispermanent = true,
      effect = function()
        cuttimemulti = cuttimemulti * 0.8
      end,
      r=235,
    },
    {
      title="Well",
      text="The well waters all your plants, so their fruit will grow 30% faster.",
      r=236,
      buildingtype=objecttypes["well"]
    },
    {
      title="Appleseed",
      text="You may plant an apple tree.",
      r=237,
      buildingtype=objecttypes["tree"]
    },
    {
      title="Appleseed",
      text="You may plant an apple tree.",
      r=237,
      buildingtype=objecttypes["tree"]
    },
    {
      title="Mine",
      text="It gives you access to an unlimited supply of stones, but they take longer to mine.",
      r=237,
      buildingtype=objecttypes["mine"]
    },
    {
      title="Sheep",
      text="Your sheep gives you wool ($  ) until you butcher it (more $  ).",
      r=237,
      buildingtype=objecttypes["sheep"]
    },
    {
      title="Sheep",
      text="Your sheep gives you wool ($  ) until you butcher it (more $  ).",
      r=237,
      buildingtype=objecttypes["sheep"]
    },
    {
      title="Woodsale",
      text="Someone pays you enormous 35$ if you sell them 10/.",
      r=239,
      cost={0,10,0,0},
      gain={0,0,30,0}
    },
    {
      title="Quickstones",
      text="If you need stones quickly, get 5# for 20$.",
      r=240,
      cost={0,0,20,0},
      gain={5,0,0,0}
    },
    {
      title="Gift",
      text="Here, have 10$ :)",
      r=241,
      cost={0,0,0,0},
      gain={0,0,10,0}
    },
    {
      title="Wood reserve",
      text="You find a lot of wood! It's 10/!",
      r=242,
      cost={0,0,0,0},
      gain={0,10,0,0}
    }
  }
  for i, card in pairs(cards) do
    card.y = 14
    if card.buildingtype then
      card.cost = card.buildingtype.cost
    end
  end
  handcards = {}
  for i = 1,5 do
    drawrandomcard()
  end
end

function drawrandomcard()
  ind = math.random(1, #cards)
  trace("Add card " .. ind .. " to hand")
  table.insert(handcards, table.shallow_copy(cards[ind]))
  cards[ind].y = 14
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

function paintcards(mx,my,onlybutton, buttoncolor)
  ci, button = 0, false

  if #handcards > 0 then
    -- effective width: 30 - 9 - 2 = 19
    if #handcards > 1 then
      wpc = 19 // (#handcards - 1)
    else
      wpc = 0
    end
    for i, card in pairs(handcards) do
      cx = 1 + (i-1) * wpc
      paintcard(cx,card.y,9,13,card.title, card.text, card.cost, card.r, onlybutton, buttoncolor)
      if mx >= cx and mx <= cx + 9 and my >= card.y and my <= card.y + 13 then
        ci = i
        if mx >= cx + 1 and mx < cx + 9 - 1 and my >= card.y + 13 - 2 and my < card.y + 13 - 1 then
          button = true
        end
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
-- 011:0000005500005566000556660056666500665656055666560666766606666776
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
-- 027:0067663400677003000000030000000300000003000000330000033400003444
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
-- 043:000000550000556600055666005666650066c256055622560666766606666776
-- 044:565000006c260000622760005666670067666600667667707766767066666700
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
-- 059:006c263400622003000000030000000300000003000000330000033400003444
-- 060:66c2700046220000407000004470000044000000440000004340000034440000
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
-- 112:00000000dddddddddeeeeeeddeeeeefddeeeeefddeeefffddddddddd00000000
-- 113:0000033000003344000334440033444003344400333340003333000003300000
-- 114:00cc11000c111110c11cc111c113131111c13113111311130111113000113300
-- 115:00c4c0000cd4dd00cdd4dde0cdd44de0cddddde00dddde0000eee00000000000
-- 116:ccc00000cdd00000cdccc000cdcdd00000cdccc000cdcdd00000cdd00000cdd0
-- 117:00000000000010003331333330010103300101033001000330d1dd033de1eed3
-- 119:000000000000000000000000000000000000ccc00000cc000000c0c00000000c
-- 120:cc0000ccc000000c00000000000000000000000000000000c000000ccc0000cc
-- 121:000000cc00000cc00000000000cc0cc00cc0cc000000000000cc00000cc00000
-- 122:00000000000c0000000c0000000c0000c00c00c00c0c0c0000ccc000000c0000
-- 123:0020022000222002000000020000000200000002000000200000020000002000
-- 124:0000200000020000002000000020000002000000020000000020000000020000
-- 128:00000000dddddd00deeeed00deeefd00defffd00dddddd000000000000000000
-- 129:0003300000334400033444003333400033330000033000000000000000000000
-- 130:00cc00000c111000c1c11300c113130001113000003300000000000000000000
-- 131:00cc00000c4dd000cd4ddf00cd44df000dddf00000ff00000000000000000000
-- 132:0ddd00000dee00000deddd000dedee00000dee00000dee000000000000000000
-- 133:3ef1ffe3df4144fded4144deffddddefefeeeffefeffffff0fefeef000ffff00
-- 135:0000000000000000000000000000000000002220000022000000202000000002
-- 136:2200002220000002000000000000000000000000000000002000000222000022
-- 137:0000002200000220000000000022022002202200000000000022000002200000
-- 138:0000000000020000000200000002000020020020020202000022200000020000
-- 144:000000cc00000cc00000000000cc0cc00cc0cc000000000000cc00000cc00000
-- 145:000000000cccccc00cccccc00cccccc0000cc000000cc000000cc00000000000
-- 146:00000000000cc00000c00c000cccccc00cccccc00cccccc000cccc0000000000
-- 147:000000000000c000000ccc0000cccccc0ccc0cc00cc00c000c00000000000000
-- 148:000000000ccc00000ccc00000ccccc000ccccc00000ccc00000ccc0000000000
-- 149:00000000000010003331333330010103300101033001000330d1dd033de1eed3
-- 150:00000000000000003000000030000000300000003000000030dd00003dee0000
-- 151:0000000000000000ccccccccc000000cc000000cc000000cc0cccc0ccc0000cc
-- 152:0000000000000000222222222000000220000002200000022022220222000022
-- 153:0000000000000000000000020000002400000242000024240002424200242424
-- 154:000000000000000040ee000024ee000042ee000024ee00004242400024242400
-- 155:0000000c000000c300000c3c00000c3300000033000003030000030d0000300d
-- 156:c000000033000000333000004340000034000000403000000030000000030000
-- 160:0000002200000220000000000022022002202200000000000022000002200000
-- 161:0000000002222220022222200222222000022000000220000002200000000000
-- 162:0000000000022000002002000222222002222220022222200022220000000000
-- 163:0000000000002000000222000022222202220220022002000200000000000000
-- 164:0000000002220000022200000222220002222200000222000002220000000000
-- 165:3ef1ffe3df4144fded4144deffddddefefeeeffefeffffff0fefeef000ffff00
-- 166:3eff0000dfffff00edffff00ffdddd0fefeeeffefeffffff0fefeef000ffff00
-- 167:c000000cc000000ccc0000ccc0cccc0cc000000cc000000c0c0000c000cccc00
-- 168:2000000220000002220000222022220220000002200000020200002000222200
-- 169:00333333003444430034a9430034994300344443003333330035336300663673
-- 170:333334004444340043343400433434004334340043d434004334340043343660
-- 171:0000300d0003000d0003000d0030000d003d000d03d0ddfd333d66fd3337766d
-- 172:00030000000030000000300000000300000d030dfee60d30fee67333ee667333
-- 173:0000000000000000000000000000000003000000030056773335667733377666
-- 174:0000000000000000000000000000000000000030775600305666733366677333
-- 176:0000000000000000000000000a30000033300000033333300034430000300300
-- 177:00000000033000003a3333033333333004344430003000300030003000300030
-- 178:00000000033000003a3ccc0333ccddd004cddde0003000300030003000300030
-- 179:00000000033cccc03accccd333ccdddd0ccdddde00cdeee00030003000300030
-- 180:00300030003000300030003004dddde033ddddd03e3ddd030330000000000000
-- 181:0000000c000000c000000c0000000c00000000c000000c0c00000c0c0000c00c
-- 182:c00000000c00000000c0000000c000000c000000c0c0000000c00000000c0000
-- 183:0000000200000020000002000000020000000020000002020000020200002002
-- 184:2000000002000000002000000020000002000000202000000020000000020000
-- 185:6566556677677676377633373333333333333343334333333333433343333333
-- 186:6566556677677676377633373333333333333343334333333333433343333333
-- 187:6577556677677676377633373333333333333343334333333333433343333333
-- 188:6566577777677676377633373333333333333343334333333333433343333333
-- 189:6566556677677676377633373333333333333343334333333333433343333333
-- 192:000000000cccccc0c0c0000ccc00000c0c00000c00ccccc000c000c000c000c0
-- 193:0000000002222220202000022200000202000002002222200020002000200020
-- 194:000000000000000000000000000d300000d33400004444000031140000333400
-- 195:0000000000000d00000003300000033000000400004444000031140000333400
-- 197:0000c00c000c000c000c000c00c0000c00c0000c0c00000cccc0000cccc0000c
-- 198:000c00000000c0000000c00000000c0000000c00000000c000000ccc00000ccc
-- 199:0000200200020002000200020020000200200002020000022220000222200002
-- 200:0002000000002000000020000000020000000200000000200000022200000222
-- 204:000000000000cccc000cdddd00cddddd0cdddddd0cdddddd0cdddddd0cdddddd
-- 205:00000000cccc00ccddddecccdddcdddddddddddddceddddddddddddddddddddd
-- 206:00000000ccccccccdddddddddddddddddddddddddddddddddddddddddddddddd
-- 207:00000000cccc0000ddddd000dddddd00dddddde0dddddde0dddddde0dddddde0
-- 210:0000000000ccbb000cbbbbb00cbbbbb00bbbbba00bbbbba000bbaa0000000000
-- 211:0000000000112200012222200122222002222240022222400022440000000000
-- 212:0000000000556600056666600566666006666670066666700066770000000000
-- 213:0000000000aa99000a9999900a99999009999980099999800099880000000000
-- 214:0000000000ccdd000cddddd00cddddd00ddddde00ddddde000ddee0000000000
-- 215:0000000000ddee000deeeee00deeeee00eeeeef00eeeeef000eeff0000000000
-- 216:ddddddddddddddddddeedddddeddddefdfdddfffdeddffedddefeddddddddddd
-- 217:ddddddddddddddddddddddddffffffffffffffffdddddddddddddddddddddddd
-- 218:ddddddddddddddddddddeeddfeddddedfffdddfddeffddeddddefedddddddddd
-- 220:0cdddddd0cdddddd0cdddddd00eddddd00cddddd0cdddddd0cdddddd0cdddddd
-- 221:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
-- 222:ddddddddddddddddddddddddddddddddddddddedddddeecddddddcdddddddddd
-- 223:dddddde0dddddde0dddddde0ddddde00ddddde00dddddee0dddddd00dddddde0
-- 224:00000000000000000000000000000000000c000000c0c00c00c00c0c0c0000c0
-- 225:000000000cc00000c00c0000c000c000c0000c0000000c0000000c00000000c0
-- 227:0000000002000200020022000202220002222200020222000200220002000200
-- 228:000000000c000c000c00cc000c0ccc000ccccc000c0ccc000c00cc000c000c00
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
-- 000:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000031101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 001:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000031101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 002:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003142000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000031101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 003:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000031101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 004:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000031101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 005:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003142000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003151101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 006:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003142000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003110101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 007:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003142000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003110104210000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 008:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003151100000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000002c3110101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 009:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002c0200000000000000000031101000000000000000000000000000000000000000000000000000000000003101014100000000000000000000000000000000000000000000000000005b0000b4000000000000000000000031505110101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 010:0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003132014100000e0000000031518042000000000000000000000000000000000000000000000000000000003151101061410000000000000000000000000000000000000000000000000000000000000000000000000000003151801010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 011:00000000000000000000000000000000000031012c0000000000000e1e0000000000000000000000000000003151101061410000000000315110101000000000000000000000000000000000000000000000000000000001511010101041b4000000000000000000000000000000000000000000000031015050015101410000b4000000315110108010421010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 012:000000000000000000020000000000b400315110324100000000000f1f0000b4000000000000000000000031514242101061323201010151102210100000000000000000000000000000000000000000000000000000001010101010104100002c0c00020000000000000000000000000000000000003110108010101061410000002c31511010801010421010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 013:00000000000031510132610141000002315110228061014100003101010141000000000000000000000031321010101010101010101042104210421000000000000000000000000000000000000000000000000000000010101010101061016101013201410000000e000e00000000000000000000003110101042101010610101010151101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 014:00000000003151104242101061010150501010421042106101015110108061010141000000b400000031514210101042101010221010421010101010000000000000000000000000000000000000000000000000000000101010101010101010101010106141000c00000002000000000099000000315110101010101010101010801042101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 015:00002c02315110102210104210421080108042104210104210101042101010101061410200000000315110101010221042424242104242424242421000000000000000000000000000000000000000000000000000000010101010101010101010101010106101010101320101410c020000002c00311010101042101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 016:010101015142421010101042104280102210101010421010421010421010221010106101015050015110421010101010101010104210101010421010000000000000000000000000000000000000000000000000000000101010101010101010101010101010101010101010106101010101325001511010101010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 027:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000210000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 032:210000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 036:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003d3d00002d002d004d00004d005d5d5d007d7d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 037:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003d003d002d002d004d004d00005d0000007d007d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 038:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003d003d00002d00004d4d0000005d5d5d007d7d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 039:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003d003d00002d00004d004d00005d0000007d007d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 040:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003d3d0000002d00004d00004d005d5d5d007d007d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 041:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 042:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111111112100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 043:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000202020202021000030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 044:00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000311000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000020202020202021303030000000700000000000b2c200000000000099a900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 045:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000202020202020303030303000357100020093a3b3c30000003b00009aaa02000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 046:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e00003110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010101010161510101010101010101010101015050015001010101010150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 047:0000000000000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000002c0000023110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101010101010101010101010101010101010801080221010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 048:0000000000000000000000000000000000000000000000000000000000000000000031320141002c000000b400b400b400b400000031010101325110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101010101010101022101010101010101010108010101022101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 049:000000000000000000000000000000000000000000000000000000000000000000315110106101014100000000000000000000310151101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101010101010101010101010101010221010101080101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 050:000000000000000000000000000000000000000000000000000000000000010101511010101010106101500101505050010101511010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101010101010101010101010101010101010101010101010101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 066:000000000000000000000000000000000000000000000000000000000000210000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 135:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000031101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
-- 000:00601060406000006040004040000000601010000060600040400040400000000000606060002040400000404040400040400000000060404000004040404000404000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000000000000000000000040404040404000000000000000000000404040404040004040404000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </FLAGS>

-- <PALETTE>
-- 000:1a1c2cceb25db13e537559573c2c24a7f07038b7640c483829366f3b5dc941a6f6b6c6f6f4f4f494b0c2566c86333c57
-- </PALETTE>

