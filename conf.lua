function love.conf(t)
    t.identity = "babgotchi"
    t.appendidentity = true
    t.version = "11.0"

    t.window.title = "Babgotchi"
    t.window.icon = "assets/sprites/bab-appicon.png"
    t.window.resizable = false
    
    t.window.minwidth = 640
    t.window.minheight = 360

    t.window.width = 1280
    t.window.height = 720
    
    t.window.vsync = 0

    t.modules.thread = false
    t.modules.video = false
end