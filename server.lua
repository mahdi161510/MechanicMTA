local DROPPED_LIFETIME = 10
local DOOR_OBJECT_MODEL = 1337

local heldDoors, workCooldown = {}, {}

local function isPlayerMechanic(player)
    return true
end

addEvent("onPlayerRequestMechanicMode", true)
addEventHandler("onPlayerRequestMechanicMode", resourceRoot, function()
    triggerClientEvent(client, "onClientMechanicModeResponse", resourceRoot, isPlayerMechanic(client))
end)

addEvent("onPlayerStartDoorWork", true)
addEventHandler("onPlayerStartDoorWork", resourceRoot, function(vehicle, targetIndex, actionType, isPanel, isWheel, isEngine)
    local player = client
    if not isElement(vehicle) or not isElement(player) then return end
    if workCooldown[player] and getTickCount() - workCooldown[player] < 500 then
        triggerClientEvent(player, "onClientWorkCancelled", resourceRoot)
        return
    end
    workCooldown[player] = getTickCount()
end)

addEvent("onPlayerFinishDoorWork", true)
addEventHandler("onPlayerFinishDoorWork", resourceRoot, function(vehicle, targetIndex, actionType, isPanel, isWheel, isEngine, isGlass)
    local player = client
    if not isElement(vehicle) or not isElement(player) then return end

    if isEngine then
        if actionType == "repair" then
            setElementHealth(vehicle, 1000)
            outputChatBox("#00FF00[مکانیک] #FFFFFFموتور تعمیر شد!", player, 255, 255, 255, true)
        end
    elseif isGlass then
        if actionType == "repair" then
            setVehiclePanelState(vehicle, 4, 0)
            outputChatBox("#00FF00[مکانیک] #FFFFFFشیشه تعمیر شد!", player, 255, 255, 255, true)
        end
    elseif isWheel then
        local fl, rl, fr, rr = getVehicleWheelStates(vehicle)
        local states = { fl, rl, fr, rr }
        if actionType == "repair" or actionType == "attach" then
            states[targetIndex + 1] = 0
            setVehicleWheelStates(vehicle, states[1], states[2], states[3], states[4])
            outputChatBox("#00FF00[مکانیک] #FFFFFFتایر تعمیر شد!", player, 255, 255, 255, true)
        end
    elseif isPanel then
        if actionType == "repair" then
            setVehiclePanelState(vehicle, targetIndex, 0)
            outputChatBox("#00FF00[مکانیک] #FFFFFFسپر تعمیر شد!", player, 255, 255, 255, true)
        end
    else
        local state = getVehicleDoorState(vehicle, targetIndex)
        if actionType == "detach" then
            if state ~= 2 and state ~= 3 then return end
            setVehicleDoorState(vehicle, targetIndex, 4, false)
            local doorObj = createObject(DOOR_OBJECT_MODEL, 0, 0, 0)
            if doorObj then
                setElementCollisionsEnabled(doorObj, false)
                attachElements(doorObj, player, 0.3, 0.5, 0.8, 0, 0, 0)
                heldDoors[player] = doorObj
                triggerClientEvent(player, "onClientHoldDoor", resourceRoot, DOOR_OBJECT_MODEL, 0.3, 0.5, 0.8, 0, 0, 0)
                outputChatBox("#00FF00[مکانیک] #FFFFFFقطعه کنده شد!", player, 255, 255, 255, true)
            end
        elseif actionType == "attach" then
            if state ~= 4 then return end
            setVehicleDoorState(vehicle, targetIndex, 0)
            outputChatBox("#00FF00[مکانیک] #FFFFFFقطعه نصب شد!", player, 255, 255, 255, true)
        elseif actionType == "repair" then
            if state ~= 2 and state ~= 3 then return end
            setVehicleDoorState(vehicle, targetIndex, 0)
            outputChatBox("#00FF00[مکانیک] #FFFFFFقطعه تعمیر شد!", player, 255, 255, 255, true)
        end
    end
end)

addEvent("onClientWorkCancelled", true)
addEventHandler("onClientWorkCancelled", resourceRoot, function() end)

addEvent("onPlayerDropHeldDoor", true)
addEventHandler("onPlayerDropHeldDoor", resourceRoot, function()
    local player = client
    local doorObj = heldDoors[player]
    if not doorObj or not isElement(doorObj) then return end
    detachElements(doorObj, player)
    setElementCollisionsEnabled(doorObj, true)
    local px, py, pz = getElementPosition(player)
    setElementPosition(doorObj, px, py, pz)
    setElementVelocity(doorObj, 0, 0, -0.5)
    heldDoors[player] = nil
    triggerClientEvent(player, "onClientDropDoor", resourceRoot)
    setTimer(function()
        if isElement(doorObj) then destroyElement(doorObj) end
    end, DROPPED_LIFETIME * 1000, 1)
end)

addEventHandler("onPlayerQuit", root, function()
    local player = source
    if heldDoors[player] and isElement(heldDoors[player]) then
        destroyElement(heldDoors[player])
    end
    heldDoors[player], workCooldown[player] = nil, nil
end)