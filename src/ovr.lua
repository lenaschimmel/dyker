
function OVR()
    local x,y,l = mouse()
    if globalstate == "title" then
      drawtitle()
      
      if l then
        globalstate = "levelstart"
      end
      
      return
    end
  
    if globalstate == "gamewon" then
      drawendscreen()
      return
    end
  
    drawlevel()
    drawobjects()
  
    if not l then
      clicklock = false
    end
    if globalstate == "levelstart" or globalstate == "play" or globalstate == "levelend" or globalstate == "restart" then
      
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
                end
              else
                ct = "Can't reach this place."
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
  
    trace("1: " ..  x .. "," .. y)
    if globalstate == "levelstart" or globalstate == "levelend" or globalstate == "restart" then
      paintframe(3,2,24,13,777)
  
      color = 12
      if x >= 8*4 and x <= 8*26 and y >= 100 and y <= 110 then
        color = 5
        trace("5")
      end
  
      trace("2")
      if globalstate == "levelstart" then
        trace("3")
        printc(levels[levelindex].name, 120,29, 15)
        textrect(levels[levelindex].introtext, 42, 55, 200 - 42)
        printc("Click here to start the level", 120,100, color)
        if color == 5 and l and clicklock == false then
          trace("4")
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
  