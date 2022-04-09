
-- TODO: adjust drawing order
--   TIC (using dynamic blue-only-palette):
--     Draw sky with single color
--     Draw water with many colors
--   OVR (using fixed no-blue-palette):
--     Draw level
--     Draw objects
--     Draw UI
--     Draw cursor

function drawsky()
  if globalstate == "title" or globalstate == "gamewon" then
    cls(10)
  else
    cls(11)
  end
end

function drawwater()
  map(levelx,levely+17,levelwidth,levelheight,-sx,0,0)
end

function drawlevel()
  map(levelx,levely,levelwidth,levelheight,-sx,0,0)
end

function drawobjects()
  for _,o in pairs(objects) do
    drawobject(o)
  end
end

function drawtitle()
  map(120,34,30,levelheight,0,0,0)
  prints("Click to start the game", 12*8, 8*8, 12)
  print("A game by @LenaSchimmel", 2*8, 14*8, 12, false, 1, false)
  print("Made in 72 hours for Ludum Dare 50", 2*8, 15*8, 12, false, 1, true)
end

function drawendscreen()
  map(120,34,30,levelheight,0,0,0)
  prints("Thank you for playing!", 12*8, 8*8, 12)
  print("You won all levels of Dyker", 2*8, 14*8, 12, false, 1, false)
  print("Come back later to see if there is a post-jam version.", 2*8, 15*8, 12, false, 1, true)
end

function myspr(sp, x, y)
  spr(sp, x*8, y*8, 0)
end

function myrspr(spa, spb, x, y, pa, r)
  sp = eitheror(spa, spb, pa, r * 13 + x * 19 + y * -5)
  spr(sp, x*8, y*8, 0)
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