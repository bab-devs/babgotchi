json = require "lib/json"
require "utils"
require "audio"

is_mobile = love.system.getOS() == "Android" or love.system.getOS() == "iOS"

sprites = {}
particles = {}

frames = 0
fpstimer = 0

fps = 0

oldmousex = 0
oldmousey = 0

babx = 0
baby = 0

babxvel = 0
babyvel = 0

babhappy = false
babhappytimeout = false

func_queue = {}

function love.load(dt)
  local libstatus, liberr = pcall(function() discordRPC = require "lib/discordRPC" end)
  if libstatus then
    discordRPC = require "lib/discordRPC"
    print("✓ discord rpc added")
  else
    print("⚠ failed to require discordrpc: "..liberr)
  end

  love.graphics.setDefaultFilter("nearest","nearest")

  local function addsprites(d)
    local dir = "assets/sprites"
    if d then
      dir = dir .. "/" .. d
    end
    local files = love.filesystem.getDirectoryItems(dir)
    for _,file in ipairs(files) do
      if string.sub(file, -4) == ".png" then
        local spritename = string.sub(file, 1, -5)
        local sprite = love.graphics.newImage(dir .. "/" .. file)
        if d then
          spritename = d .. "/" .. spritename
        end
        sprites[spritename] = sprite
        --print("ℹ️ added sprite "..spritename)
      elseif love.filesystem.getInfo(dir .. "/" .. file).type == "directory" then
        print("ℹ️ found sprite dir: " .. file)
        local newdir = file
        if d then
          newdir = d .. "/" .. newdir
        end
        addsprites(file)
      end
    end
  end

  addsprites()
  print("✓ added sprites\n")

  sound_exists = {}
  local function addAudio(d)
    local dir = "assets/audio"
    if d then
      dir = dir .. "/" .. d
    end
    local files = love.filesystem.getDirectoryItems(dir)
    for _,file in ipairs(files) do
      if love.filesystem.getInfo(dir .. "/" .. file).type == "directory" then
        local newdir = file
        if d then
          newdir = d .. "/" .. newdir
        end
        addAudio(file)
      else
        local audioname = file
        if file:ends(".wav") then audioname = file:sub(1, -5) end
        if file:ends(".mp3") then audioname = file:sub(1, -5) end
        if file:ends(".ogg") then audioname = file:sub(1, -5) end
        if file:ends(".xm") then audioname = file:sub(1, -4) end
        if d then
          audioname = d .. "/" .. audioname
        end
        sound_exists[audioname] = true
        --print("ℹ️ audio "..audioname.." added")
      end
    end
  end
  addAudio()
  print("✓ audio added")

  if discordRPC and discordRPC ~= true then
    discordRPC.initialize("592438892355911680", true) -- app belongs to thefox, contact him if you wish to make any changes
    print("✓ discord rpc initialized")
  end

  print("\nboot complete!")

  baby = love.graphics.getHeight()-sprites["bab"]:getHeight()

  if not is_mobile then
    love.mouse.setCursor(love.mouse.newCursor(love.image.newImageData(32, 32)))
  end

  resetMusic("babgotchi", 0.5)
end

function love.update(dt)
  babhappy = false
  fpstimer = fpstimer + dt

  if fpstimer >= 1 then
    fps = frames/fpstimer
    fpstimer = 0
    frames = 0
  end

  for i,qf in pairs(func_queue) do
    if qf[2]+qf[3] < love.timer.getTime() then
      qf[1]()
      table.remove(func_queue, i)
    end
  end

  for i,particle in ipairs(particles) do
    if not particle.lifetime then
      particle.lifetime = 0
    end

    if particle.type == "food" then
      local gravity = 0.05+particle.seed/10

      particle.rot = particle.rot + particle.yvel/2 + particle.xvel/2

      particle.x = particle.x + particle.xvel * dt * 100
      particle.y = particle.y + particle.yvel * dt * 100

      particle.xvel = particle.xvel * 0.99
      particle.yvel = particle.yvel + gravity * dt * 100

      if particle.y+10 > love.graphics.getHeight() then
        particle.yvel = 0-particle.yvel*0.9
        particle.y = love.graphics.getHeight()-10
      elseif particle.y-10 < 0 then
        particle.yvel = 0-particle.yvel*0.9
        particle.y = 10
      end

      if particle.x+10 > love.graphics.getWidth() then
        particle.xvel = 0-particle.xvel
        particle.x = love.graphics.getWidth()-10
      elseif particle.x-10 < 0 then
        particle.xvel = 0-particle.xvel
        particle.x = 10
      end

      if particle.yvel < 1 and particle.yvel > -1 and particle.y+20 > love.graphics.getHeight() then --just for the particle demo
        table.remove(particles, i)
      end

      if pointOverBox(particle.x, particle.y, babx, baby, sprites["bab"]:getWidth(), sprites["bab"]:getHeight()) then
        table.remove(particles, i)
        babhappy = true

        local function bh()
          babhappy = false
        end

        deleteActions(bh)
        queueAction(bh, 1)
        -- insert snacc sound effect here
      end
    elseif particle.type == "heart" then
      if not particle.velorig then
        particle.velorig = particle.xvel
      end
      if particle.lifetime > (1 + particle.seed * 2) then
        particle.xvel = particle.xvel * 0.95
        particle.yvel = particle.yvel * 0.95
      end

      particle.alpha = particle.xvel/particle.velorig

      particle.x = particle.x + particle.xvel * dt * 100
      particle.y = particle.y + particle.yvel * dt * 100

      particle.lifetime = particle.lifetime + dt

      if particle.alpha < 0 then
        table.remove(particles, i)
      end
    end
  end

  if love.keyboard.isDown("d") then --just for the particle demo, going to be controlled by an ai later
    babxvel = babxvel + dt * 10
  end
  if love.keyboard.isDown("a") then
    babxvel = babxvel - dt * 10
  end
  if love.keyboard.isDown("w") and baby >= love.graphics.getHeight()-sprites["bab"]:getHeight() then
    babyvel = -5
  end

  local gravity = 0.1

  babx = babx + babxvel * dt * 100
  baby = baby + babyvel * dt * 100

  babxvel = babxvel * 0.99
  if not (baby >= love.graphics.getHeight()-sprites["bab"]:getHeight()) then
    babyvel = babyvel + gravity * dt * 100
  else
    babyvel = 0
  end

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

  babx = limit(babx, 0, love.graphics.getWidth()-sprites["bab"]:getWidth())
  baby = limit(baby, 0, love.graphics.getHeight()-sprites["bab"]:getHeight())

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

  oldmousex, oldmousey = love.mouse.getPosition()
end

function love.draw()
  frames = frames + 1

  local bgsprite = sprites["house-bg"]
  love.graphics.draw(bgsprite, 0, 0, 0, love.graphics.getWidth()/bgsprite:getWidth(), love.graphics.getWidth()/bgsprite:getWidth())

  for _,particle in ipairs(particles) do
    if particle.type == "food" then
      love.graphics.push()

      love.graphics.translate(particle.x, particle.y)

      love.graphics.translate(10 / 2,  10 / 2)
      love.graphics.rotate(math.rad(particle.rot))
      love.graphics.translate(-10 / 2, -10 / 2)

      love.graphics.setColor(hslToRgb(particle.crtime%1, 0.5, 0.7))
      love.graphics.rectangle("fill", 0, 0, 10, 10)
      love.graphics.setColor(hslToRgb(particle.crtime%1, 0.5, 0.5))
      love.graphics.rectangle("fill", 2, 2, 6, 6)

      love.graphics.pop()
    elseif particle.type == "heart" then
      love.graphics.push()

      love.graphics.translate(particle.x, particle.y)

      love.graphics.translate(sprites["heart"]:getWidth() / 2,  sprites["heart"]:getHeight() / 2)
      love.graphics.translate(-sprites["heart"]:getWidth() / 2, -sprites["heart"]:getHeight() / 2)

      love.graphics.setColor(244/255, 66/255, 223/255, particle.alpha)
      love.graphics.draw(sprites["heart"], 0, 0)

      love.graphics.pop()
    end
  end

  local babsprite = sprites["bab"]
 
  if babhappy then
    babsprite = sprites["babhappy"]
  end

  love.graphics.setColor(1,1,1)
  love.graphics.draw(babsprite, babx, baby)

  local mousspritename
  if mouseOverBox(babx, baby, babsprite:getWidth(), babsprite:getHeight()) then
    mousspritename = "han"
  else
    mousspritename = "mous"
  end
  local moussprite = sprites[mousspritename]

  love.graphics.setColor(0, 0, 0)
  love.graphics.draw(moussprite, love.mouse.getX()-1, love.mouse.getY()-1, 0, (moussprite:getWidth()+11)/moussprite:getWidth(), (moussprite:getHeight()+5)/moussprite:getHeight())
  love.graphics.setColor(1, 1, 1)
  love.graphics.draw(moussprite, love.mouse.getX(), love.mouse.getY())

  love.graphics.print(math.floor(fps*100)/100 .. "FPS")
end

function love.mousereleased(x, y, button)
  if button == 2 then
    mouseholdingbab = false
  end
end