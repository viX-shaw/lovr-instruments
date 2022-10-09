local filesState = {}
local sTime = lovr.timer.getTime()

function reloadIfChanged()
    if lovr.timer.getTime() - sTime > 1.0 then
        sTime = lovr.timer.getTime()
        newFileState = loadSourceInfo()
        if newFileState ~= filesState then
            filesState = newFileState
            lovr.event.restart()
        end

    end
end

function loadSourceInfo()
    bytesInfoAllSourceFiles = {}
    for idx, en in lovr.filesystem.getDirectoryItems(lovr.filesystem.getSaveDirectory.."/files") do
        if lovr.filesystem.isFile(en) then
            _, bytes = lovr.filesystem.read(en)
            table.insert(bytesInfoAllSourceFiles, bytes)
        end
    end
    return bytesInfoAllSourceFiles
end

filesState = loadSourceInfo()