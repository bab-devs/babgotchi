json = require "lib/json"
require "utils"

is_mobile = love.system.getOS() == "Android" or love.system.getOS() == "iOS"

sprites = {}
particles = {}

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
end

function love.update(dt)
  for i,particle in ipairs(particles) do
    if particle.type == "food" then
      local gravity = 0.05+particle.seed/100

      particle.rot = particle.rot + particle.yvel/2

      particle.x = particle.x + particle.xvel+dt
      particle.y = particle.y + particle.yvel+dt

      particle.xvel = particle.xvel * 0.9
      particle.yvel = particle.yvel + gravity

      if particle.y+10 > love.graphics.getHeight() then
        particle.yvel = 0-particle.yvel*0.8
        particle.y = love.graphics.getHeight()-10
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
    table.insert(particles, {type = "food", x = love.mouse.getX(), y = love.mouse.getY(), xvel = math.random(-10.0, 10.0), yvel = math.random(-3.0, 0.0), rot = 0, seed = math.random(0.000, 1.000)})
  end

  if love.keyboard.isDown("d") then --just for the particle demo, going to be controlled by an ai later
    babx = babx + 2
  end
  if love.keyboard.isDown("a") then
    babx = babx - 2
  end
  if love.keyboard.isDown("w") then
    baby = baby - 2
  end
  if love.keyboard.isDown("s") then
    baby = baby + 2
  end
end

function love.draw()
  love.graphics.setBackgroundColor(hslToRgb(love.timer.getTime()/3%1, 0.5, 0.5))
  love.graphics.printf("babgotchi testing !!!", 0, 0, love.graphics.getWidth(), "center")

  for _,particle in ipairs(particles) do
    love.graphics.push()

    love.graphics.translate(particle.x, particle.y)

    love.graphics.translate(10 / 2,  10 / 2)
    love.graphics.rotate(math.rad(particle.rot))
    love.graphics.translate(-10 / 2, -10 / 2)

    love.graphics.rectangle("fill", 0, 0, 10, 10)

    love.graphics.pop()
  end

  local babsprite = sprites["bab"]
  love.graphics.draw(babsprite, babx, baby)

  love.graphics.setColor(0, 0, 0)
  love.graphics.draw(sprites["mous"], love.mouse.getX()-1, love.mouse.getY()-1, 0, (sprites["mous"]:getWidth()+11)/sprites["mous"]:getWidth(), (sprites["mous"]:getHeight()+5)/sprites["mous"]:getHeight())
  love.graphics.setColor(1, 1, 1)
  love.graphics.draw(sprites["mous"], love.mouse.getX(), love.mouse.getY())
end