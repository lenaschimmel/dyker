
function TIC()
    drawsky()
    drawwater()
  
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
            if tl <= 0 then -- start doing it
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
  
    if globalstate == "gamewon" then
      return
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
  end
  