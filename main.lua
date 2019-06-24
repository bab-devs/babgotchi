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

  if not is_mobile then
    love.mouse.setCursor(love.mouse.newCursor(love.image.newImageData(32, 32)))
  end

  babx = 0
  baby = love.graphics.getHeight()-sprites["bab"]:getHeight()

  resetMusic("babgotchi", 0.5)
end

function love.update(dt)
  fpstimer = fpstimer + dt

  if fpstimer >= 1 then
    fps = frames/fpstimer
    fpstimer = 0
    frames = 0
  end

  for i,particle in ipairs(particles) do
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
        -- insert snacc sound effect here
      end
    end
  end

  if love.mouse.isDown(1) then
    table.insert(particles, {type = "food", x = love.mouse.getX(), y = love.mouse.getY(), xvel = (love.mouse.getX()-oldmousex)/2+math.random(-100,100)/100, yvel = (love.mouse.getY()-oldmousey)/2+math.random(-100,100)/100, rot = 0, seed = math.random(0, 10000)/10000})
  end

  if love.keyboard.isDown("d") and not (babx > love.graphics.getWidth()-sprites["bab"]:getWidth()) then --just for the particle demo, going to be controlled by an ai later
    babx = babx + dt * 400
  end
  if love.keyboard.isDown("a") and not (babx < 0) then
    babx = babx - dt * 400
  end
  if love.keyboard.isDown("w") and not (baby < 0) then
    baby = baby - dt * 400
  end
  if love.keyboard.isDown("s") and not (baby > love.graphics.getHeight()-sprites["bab"]:getHeight()) then
    baby = baby + dt * 400
  end

  oldmousex, oldmousey = love.mouse.getPosition()
end

function love.draw()
  frames = frames + 1

  local bgsprite = sprites["house-bg"]
  love.graphics.draw(bgsprite, 0, 0, 0, love.graphics.getWidth()/bgsprite:getWidth(), love.graphics.getWidth()/bgsprite:getWidth())

  for _,particle in ipairs(particles) do
    love.graphics.push()

    love.graphics.translate(particle.x, particle.y)

    love.graphics.translate(10 / 2,  10 / 2)
    love.graphics.rotate(math.rad(particle.rot))
    love.graphics.translate(-10 / 2, -10 / 2)

    love.graphics.setColor(hslToRgb(particle.seed, 0.5, 0.7))
    love.graphics.rectangle("fill", 0, 0, 10, 10)
    love.graphics.setColor(hslToRgb(particle.seed, 0.5, 0.5))
    love.graphics.rectangle("fill", 2, 2, 6, 6)

    love.graphics.pop()
  end

  local babsprite = sprites["bab"]
  love.graphics.setColor(1,1,1)
  love.graphics.draw(babsprite, babx, baby)

  love.graphics.setColor(0, 0, 0)
  love.graphics.draw(sprites["mous"], love.mouse.getX()-1, love.mouse.getY()-1, 0, (sprites["mous"]:getWidth()+11)/sprites["mous"]:getWidth(), (sprites["mous"]:getHeight()+5)/sprites["mous"]:getHeight())
  love.graphics.setColor(1, 1, 1)
  love.graphics.draw(sprites["mous"], love.mouse.getX(), love.mouse.getY())

  love.graphics.print(math.floor(fps*100)/100 .. "FPS")
end