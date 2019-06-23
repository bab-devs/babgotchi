function love.conf(t)
    t.identity = "babgotchi"
    t.appendidentity = true
    t.version = "11.0"

    t.window.title = "Babgotchi"
    t.window.icon = "assets/sprites/bab appicon.png"
    t.window.resizable = true
    t.window.minwidth = 600
    t.window.minheight = 600
    t.window.vsync = 0

    t.modules.thread = false
    t.modules.video = false
end