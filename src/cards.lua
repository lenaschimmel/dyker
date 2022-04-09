
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
      text="With this improved axe, you can cut trees and rocks 20% faster.",
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

function paintcardbutton(x,y,c)
  printc("PLAY CARD", x, y, c)
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
