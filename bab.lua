babx = 0
baby = 0
babhappy = false
babhappytimeout = false
babhunger = 40
babhungertimeout = false
babmood = 20
babmoodtimeout = false

local babxvel = 0
local babyvel = 0
local babfacing = 1

local babaiphase = 'idle'
local babaixseek = 0
local babaiindexseek = 1
babaiidlefacing = nil

local gravity = 0.1

local function update(dt)
  babhappy = false

  -- update all movement and velocity

  babx = babx + babxvel * dt * 100
  baby = baby + babyvel * dt * 100

  babxvel = babxvel * 0.99
  if not (baby >= love.graphics.getHeight()-sprites["bab"]:getHeight()) then
    babyvel = babyvel + gravity * dt * 100
  else
    babyvel = 0
  end

  -- bab petting and feeding

  if love.mouse.isDown(1) and not mouseOverBox(babx, baby, sprites["bab"]:getWidth(), sprites["bab"]:getHeight()) then
    table.insert(particles, {
        type = "food", 
        x = love.mouse.getX(), 
        y = love.mouse.getY(), 
        xvel = (love.mouse.getX()-oldmousex)/2+math.random(-100,100)/100, 
        yvel = (love.mouse.getY()-oldmousey)/2+math.random(-100,100)/100, 
        rot = 0, 
        seed = math.random(0, 10000)/100000, 
        crtime = love.timer.getTime()
      })
  elseif love.mouse.isDown(1) and mouseOverBox(babx, baby, sprites["bab"]:getWidth(), sprites["bab"]:getHeight()) and ((oldmousex ~= love.mouse.getX() and oldmousey ~= love.mouse.getY()) or babhappytimeout) then
    babhappy = true

    if oldmousex ~= love.mouse.getX() and oldmousey ~= love.mouse.getY() then
      babhappytimeout = true

      local function bht()
        babhappytimeout = false
      end

      deleteActions(bht)
      queueAction(bht, 1)
    end
  elseif love.mouse.isDown(2) and (mouseOverBox(babx, baby, sprites["bab"]:getWidth(), sprites["bab"]:getHeight()) or mouseholdingbab) then
    babx = love.mouse.getX() - sprites["bab"]:getWidth()/3
    baby = love.mouse.getY() - sprites["bab"]:getHeight()/3
    babxvel = love.mouse.getX()-oldmousex
    babyvel = love.mouse.getY()-oldmousey

    mouseholdingbab = true
  end

  -- limit bab to only the box the game is contained in

  if babx ~= limit(babx, 0, love.graphics.getWidth()-sprites["bab"]:getWidth()) then
    babx = limit(babx, 0, love.graphics.getWidth()-sprites["bab"]:getWidth())
    babxvel = -babxvel*0.6

    babfacing = -babfacing
    if babaiidlefacing then
      babaiidlefacing = 0

      for i=1, math.random(2,5) do
        table.insert(particles, {
          type = "heart",
          x = babx+math.random(0, sprites["bab"]:getWidth()),
          y = baby-math.random(-5,5),
          xvel = math.random(-10, 10)/100,
          yvel = math.random(-10, 10)/100,
          seed = math.random(0, 10000)/100000,
          star = true
        })
      end
    end
  end
  baby = limit(baby, 0, love.graphics.getHeight()-sprites["bab"]:getHeight())

  -- heart particles when bab's happy

  if babhappy and math.random(1,10) == 1 then
    table.insert(particles, {
      type = "heart",
      x = babx+math.random(0, sprites["bab"]:getWidth()),
      y = baby-math.random(-5,5),
      xvel = math.random(-10, 10)/100,
      yvel = math.random(-10, 10)/100,
      seed = math.random(0, 10000)/100000
    })
  end

  -- increase mood when bab is happy

  if babhappy then
    babmood = babmood + 0.2
  end

  -- take away 1% of bab's mood every 10 seconds

  if not babmoodtimeout then
    babmoodtimeout = true
    babmood = babmood - 1
    
    local function bmt()
      babmoodtimeout = false
    end
    queueAction(bmt, 10)
  end

  -- take away 1% of bab's satisfaction every 6 seconds

  if not babhungertimeout then
    babhungertimeout = true
    babhunger = babhunger - 1
    
    local function bht()
      babhungertimeout = false
    end
    queueAction(bht, 6)
  end

  -- ai!!!!

  if #table.match(particles, {type = "food"}) > 0 and babaiphase ~= "jump" then
    local match = table.match(particles, {type = "food"})

    babaiphase = "seek"
    if not babaiindexseek or not match[babaiindexseek] then
      babaiindexseek = math.random(1, #match)
    end

    babaixseek = match[babaiindexseek].x
  end

  if babaiphase == "seek" then
    -- the seek phase is for when bab sees food! bab will see food regardless of if bab is facing to the food or not
    -- once detecting a bit of food, bab will run to it and jump in hopes of catching it if its flying and switches to the jump phase
    -- this repeats until there's no food left, in which case bab returns back to idle phase

    -- babaixseek is the x coordinate of the food bit bab is trying to catch. bab stores it so it wont run around aimlessly if there are more than 1 bits of food

    if babx < babaixseek-10 then
      babxvel = babxvel + dt * 10
      babfacing = 1
    elseif babx > babaixseek + 10 then
      babxvel = babxvel - dt * 10
      babfacing = -1
    elseif baby >= love.graphics.getHeight()-sprites["bab"]:getHeight() then
      babaiphase = "jump"
      babyvel = math.random(-3,-6)
    end
  elseif babaiphase == "jump" then
    -- the jump phase is when bab jumps during a seek phase! all other ai is stopped until bab drops to the floor, in which case bab goes back to idle mode

    if baby >= love.graphics.getHeight()-sprites["bab"]:getHeight() then
      babaiphase = "idle"
    end
  elseif babaiphase == "idle" then
    -- the idle phase is to get bab to do something if nothing's intresting is happening. bab will walk around and take a nap (currently unimplemented)!
    -- change bab's dir once in a while to keep it intresting

    if not babaiidlefacing then
      babaiidlefacing = math.random(-1, 1)

      local function refreshfacing()
        babaiidlefacing = nil
      end

      queueAction(refreshfacing, math.random(1,5))
    end

    -- dir fixing for if bab's about to crash into a "wall"

    if babaiidlefacing ~= 0 and babx ~= limit(babx, 20, love.graphics.getWidth()-sprites["bab"]:getWidth()-20) and not babalreadyfixeddirfrombeingcrashdir then
      babaiidlefacing = -babaiidlefacing
      babalreadyfixeddirfrombeingcrashdir = true

      local function antifixdir()
        babalreadyfixeddirfrombeingcrashdir = false
      end

      queueAction(antifixdir, 1)
    end

    -- move bab according to its dir

    if babaiidlefacing == 1 then
      babxvel = babxvel + dt * 3
      babfacing = 1
    elseif babaiidlefacing == -1 then
      babxvel = babxvel - dt * 3
      babfacing = -1
    end
  end

  --[[if love.keyboard.isDown("d") then
    babxvel = babxvel + dt * 10
    babfacing = 1
  end
  if love.keyboard.isDown("a") then
    babxvel = babxvel - dt * 10
    babfacing = -1
  end
  if love.keyboard.isDown("w") and baby >= love.graphics.getHeight()-sprites["bab"]:getHeight() then
    babyvel = -5
  end]]
end

local function draw()
  local babsprite = sprites["bab"]
 
  if babhappy then
    babsprite = sprites["babhappy"]
  end

  local babxdraw = babx
  if babfacing == -1 then
    babxdraw = babx + babsprite:getWidth()
  end

  love.graphics.setColor(1,1,1)
  love.graphics.draw(babsprite, babxdraw, baby, 0, babfacing, 1)
end

local function babclear()
  babx = 0
  baby = 0
  babxvel = 0
  babyvel = 0
  babfacing = 1
  babhappy = false
  babhappytimeout = false
  babhunger = 40
  babhungertimeout = false
  babmood = 20
  babmoodtimeout = false
  babaiphase = 'idle'
  babaixseek = 0
  babaiidlefacing = nil
  babaiindexseek = 1
end

local function load()
  babclear()
end

return {
  update = update,
  draw = draw,
  load = load
}