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
        local x = o.x*8-sx
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
        local x = o.x*8-sx
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
          if o.tta <= 0 then
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
        local x = o.x*8-sx
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
          if o.tta <= 0 then
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
        local x = o.x*8-sx
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