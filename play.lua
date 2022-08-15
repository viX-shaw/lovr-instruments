require 'lovr.filesystem'
local http = require('luajit-request')

local lovr = {thread = require 'lovr.thread'}

local channelName = ...
local channel = lovr.thread.getChannel(channelName)

while true do
    local url = 'http://localhost:5006/pythonOSC/%d/0.4'
    local _, present = channel:peek()
    if present then
        url = string.format(url, channel:pop())
        http.send(url)
        print("Sending Note ...")
    end
end