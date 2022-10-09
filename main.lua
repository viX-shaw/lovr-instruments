require 'utils'
local httpclient = require('luajit-request')
-- local socket = require "socket"
local scene = require('scene')
local sTime = lovr.timer.getTime()

-- function lovr.draw()
--     lovr.timer.sleep(5)
--     local res = httpclient.send('http://127.0.0.1:5006/pythonOSC/52/0.4')

--     print(res.code)
--     print(res.body)
-- end

function lovr.load()
    scene.load()
end

function lovr.draw()
    scene.draw()
end

function lovr.update(dt)
    scene.update(dt)
    reloadIfChanged()
end

function lovr.quit()
    scene.clean()
end

function lovr.restart()
    print("Restart Event received..")
end

