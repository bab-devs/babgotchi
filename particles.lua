local function update(dt)
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

        babhunger = babhunger + 0.5
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
end

local function draw()
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
end

return {
  update = update,
  draw = draw 
}