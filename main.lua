local httpclient = require('luajit-request')
-- local socket = require "socket"

function lovr.draw()
    lovr.timer.sleep(5)
    local res = httpclient.send('http://127.0.0.1:5006/pythonOSC/52/0.4')

    print(res.code)
    print(res.body)
end