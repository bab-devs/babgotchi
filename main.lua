json = require "lib/json"
require "utils"
require "audio"

bab = require "bab"
particle = require "particles"

is_mobile = love.system.getOS() == "Android" or love.system.getOS() == "iOS"

function love.load()
  clear()

  local libstatus, liberr = pcall(function() discordRPC = require "lib/discordRPC" end)
  if libstatus then
    discordRPC = require "lib/discordRPC"
    print("✓ discord rpc added")
  else
    print("⚠ failed to require discordrpc: "..liberr)
  end

  love.graphics.setDefaultFilter("nearest","nearest")

  sprites = {}
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

  bab.load()
  print("\nboot complete!")

  baby = love.graphics.getHeight()-sprites["bab"]:getHeight()

  if not is_mobile then
    love.mouse.setCursor(love.mouse.newCursor(love.image.newImageData(32, 32)))
  end

  resetMusic("babgotchi", 0.5)
end

function love.update(dt)
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

  bab.update(dt)
  particle.update(dt)

  if love.keyboard.isDown("d") then --just for the particle demo, going to be controlled by an ai later
    babxvel = babxvel + dt * 10
    babfacing = 1
  end
  if love.keyboard.isDown("a") then
    babxvel = babxvel - dt * 10
    babfacing = -1
  end
  if love.keyboard.isDown("w") and baby >= love.graphics.getHeight()-sprites["bab"]:getHeight() then
    babyvel = -5
  end

  babmood = limit(babmood, -50, 100)
  babhunger = limit(babhunger, -50, 100)
  
  oldmousex, oldmousey = love.mouse.getPosition()
end

function love.draw()
  frames = frames + 1

  local bgsprite = sprites["house-bg"]
  love.graphics.draw(bgsprite, 0, 0, 0, love.graphics.getWidth()/bgsprite:getWidth(), love.graphics.getWidth()/bgsprite:getWidth())

  bab.draw()
  particle.draw()

  love.graphics.setColor(0,1,0)
  love.graphics.rectangle("fill", love.graphics.getWidth()-110, 10, babmood, 30)
  love.graphics.setColor(0,0,0)
  love.graphics.rectangle("line", love.graphics.getWidth()-110, 10, 100, 30)

  love.graphics.setColor(1,1,0)
  love.graphics.rectangle("fill", love.graphics.getWidth()-110, 50, babhunger, 30)
  love.graphics.setColor(0,0,0)
  love.graphics.rectangle("line", love.graphics.getWidth()-110, 50, 100, 30)

  local mousspritename
  if mouseOverBox(babx, baby, sprites["bab"]:getWidth(), sprites["bab"]:getHeight()) then
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