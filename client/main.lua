ESX = nil

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(0)
    end

    while ESX.GetPlayerData().job == nil do
        Citizen.Wait(10)
    end

    PlayerData = ESX.GetPlayerData()

    RegisterNetEvent('esx:playerLoaded')
    AddEventHandler('esx:playerLoaded', function(xPlayer)
        PlayerData = xPlayer
    end)

    RegisterNetEvent('esx:setJob')
    AddEventHandler('esx:setJob', function(job)
        PlayerData.job = job
    end)

end)

isDead = false
local inRadialMenu = false

local jobIndex = nil
local adminIndex = nil
local vehicleIndex = nil

local DynamicMenuItems = {}
local FinalMenuItems = {}
-- Functions

local function deepcopy(orig) -- modified the deep copy function from http://lua-users.org/wiki/CopyTable
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        if not orig.canOpen or orig.canOpen() then
            local toRemove = {}
            copy = {}
            for orig_key, orig_value in next, orig, nil do
                if type(orig_value) == 'table' then
                    if not orig_value.canOpen or orig_value.canOpen() then
                        copy[deepcopy(orig_key)] = deepcopy(orig_value)
                    else
                        toRemove[orig_key] = true
                    end
                else
                    copy[deepcopy(orig_key)] = deepcopy(orig_value)
                end
            end
            for i=1, #toRemove do table.remove(copy, i) --[[ Using this to make sure all indexes get re-indexed and no empty spaces are in the radialmenu ]] end
            if copy and next(copy) then setmetatable(copy, deepcopy(getmetatable(orig))) end
        end
    elseif orig_type ~= 'function' then
        copy = orig
    end
    return copy
end

local function getNearestVeh()
    local pos = GetEntityCoords(PlayerPedId())
    local entityWorld = GetOffsetFromEntityInWorldCoords(PlayerPedId(), 0.0, 20.0, 0.0)
    local rayHandle = CastRayPointToPoint(pos.x, pos.y, pos.z, entityWorld.x, entityWorld.y, entityWorld.z, 10, PlayerPedId(), 0)
    local _, _, _, _, vehicleHandle = GetRaycastResult(rayHandle)
    return vehicleHandle
end

local function AddOption(data, id)
    local menuID = id ~= nil and id or (#DynamicMenuItems + 1)
    DynamicMenuItems[menuID] = deepcopy(data)
    return menuID
end

local function RemoveOption(id)
    DynamicMenuItems[id] = nil
end

local function SetupJobMenu()
    local JobMenu = {
        id = 'jobinteractions',
        title = 'Trabajo',
        icon = 'briefcase',
        items = {}
    }
    if Config.JobInteractions[PlayerData.job.name] and next(Config.JobInteractions[PlayerData.job.name]) then
        JobMenu.items = Config.JobInteractions[PlayerData.job.name]
    end

    if #JobMenu.items == 0 then
        if jobIndex then
            RemoveOption(jobIndex)
            jobIndex = nil
        end
    else
        jobIndex = AddOption(JobMenu, jobIndex)
    end
end

local function SetupAdminMenu()
    local AdminMenu = {
        id = 'adminmenu',
        title = 'Menu de Administración',
        icon = 'bussines-time',
        items = Config.AdminMenu
    }
    if PlayerData.isAdmin then
        adminIndex = AddOption(AdminMenu, adminIndex)
    end
end

--local function SetupVehicleMenu()
--    local VehicleMenu = {
--        id = 'vehicle',
--        title = 'Vehicle',
--        icon = 'car',
--        items = {}
--    }
--
--    local ped = PlayerPedId()
--    local Vehicle = GetVehiclePedIsIn(ped) ~= 0 and GetVehiclePedIsIn(ped) or getNearestVeh()
--    if Vehicle ~= 0 then
--        VehicleMenu.items[#VehicleMenu.items+1] = Config.VehicleDoors
--        if Config.EnableExtraMenu then VehicleMenu.items[#VehicleMenu.items+1] = Config.VehicleExtras end
--
--        if IsPedInAnyVehicle(ped) then
--            local seatIndex = #VehicleMenu.items+1
--            VehicleMenu.items[seatIndex] = deepcopy(Config.VehicleSeats)
--
--            local seatTable = {
--                [1] = traslatear("options.driver_seat"),
--                [2] = traslatear("options.passenger_seat"),
--                [3] = traslatear("options.rear_left_seat"),
--                [4] = traslatear("options.rear_right_seat"),
--            }
--
--            local AmountOfSeats = GetVehicleModelNumberOfSeats(GetEntityModel(Vehicle))
--            for i = 1, AmountOfSeats do
--                local newIndex = #VehicleMenu.items[seatIndex].items+1
--                VehicleMenu.items[seatIndex].items[newIndex] = {
--                    id = i - 2,
--                    title = seatTable[i] or traslatear("options.other_seats"),
--                    icon = 'caret-up',
--                    type = 'client',
--                    event = 'qb-radialmenu:client:ChangeSeat',
--                    shouldClose = false,
--                }
--            end
--        end
--    end
--
--    if #VehicleMenu.items == 0 then
--        if vehicleIndex then
--            RemoveOption(vehicleIndex)
--            vehicleIndex = nil
--        end
--    else
--        vehicleIndex = AddOption(VehicleMenu, vehicleIndex)
--    end
--end

local function SetupSubItems()
    SetupJobMenu()
--    SetupVehicleMenu()
end

local function selectOption(t, t2)
    for k, v in pairs(t) do
        if v.items then
            local found, hasAction = selectOption(v.items, t2)
            if found then return true, hasAction end
        else
            if v.id == t2.id and ((v.event and v.event == t2.event) or v.action) and (not v.canOpen or v.canOpen()) then
                return true, v.action
            end
        end
    end
    return false
end

local function IsPoliceOrEMS()
    return (PlayerData.job.name == "police" or PlayerData.job.name == "ambulance")
end

AddEventHandler('esx:onPlayerSpawn', function()
    isDead = false
end)

AddEventHandler('esx:onPlayerDeath', function(data)
    isDead = true
end)

local function IsDowned()
    return isDead
end

local function SetupRadialMenu()
    FinalMenuItems = {}
    if (IsDowned() and IsPoliceOrEMS()) then
            FinalMenuItems = {
                [1] = {
                    id = 'emergencybutton2',
                    title = traslatear("options.emergency_button"),
                    icon = 'exclamation-circle',
                    type = 'client',
                    event = 'police:client:SendPoliceEmergencyAlert',
                    shouldClose = true,
                },
            }
    else
        SetupSubItems()
        FinalMenuItems = deepcopy(Config.MenuItems)
        for _, v in pairs(DynamicMenuItems) do
            FinalMenuItems[#FinalMenuItems+1] = v
        end

    end
end

local function setRadialState(bool, sendMessage, delay)
    -- Menuitems have to be added only once

    if bool then
        TriggerEvent('qb-radialmenu:client:onRadialmenuOpen')
        SetupRadialMenu()
    else
        TriggerEvent('qb-radialmenu:client:onRadialmenuClose')
    end

    SetNuiFocus(bool, bool)
    if sendMessage then
        SendNUIMessage({
            action = "ui",
            radial = bool,
            items = FinalMenuItems
        })
    end
    if delay then Wait(500) end
    inRadialMenu = bool
end

-- Command

RegisterCommand('radialmenu', function()
    if ((IsDowned() and IsPoliceOrEMS()) or not IsDowned()) and not IsPedCuffed(ped) and not IsPauseMenuActive() and not inRadialMenu then
        setRadialState(true, true)
        SetCursorLocation(0.5, 0.5)
    end
end)

RegisterKeyMapping('radialmenu', traslatear("general.command_description"), 'keyboard', 'G')

-- Events



RegisterNetEvent('qb-radialmenu:client:noPlayers', function()
    ESX.ShowHelpNotification(traslatear("error.no_people_nearby"), 'error', 2500)
end)

--RegisterNetEvent('qb-radialmenu:abririnventario', function()
--    print("hemos llegao")
--end)

RegisterNetEvent('qb-radialmenu:client:openDoor', function(data)
    local string = data.id
    local replace = string:gsub("door", "")
    local door = tonumber(replace)
    local ped = PlayerPedId()
    local closestVehicle = GetVehiclePedIsIn(ped) ~= 0 and GetVehiclePedIsIn(ped) or getNearestVeh()
    if closestVehicle ~= 0 then
        if closestVehicle ~= GetVehiclePedIsIn(ped) then
            local plate = QBCore.Functions.GetPlate(closestVehicle)
            if GetVehicleDoorAngleRatio(closestVehicle, door) > 0.0 then
                if not IsVehicleSeatFree(closestVehicle, -1) then
                    TriggerServerEvent('qb-radialmenu:trunk:server:Door', false, plate, door)
                else
                    SetVehicleDoorShut(closestVehicle, door, false)
                end
            else
                if not IsVehicleSeatFree(closestVehicle, -1) then
                    TriggerServerEvent('qb-radialmenu:trunk:server:Door', true, plate, door)
                else
                    SetVehicleDoorOpen(closestVehicle, door, false, false)
                end
            end
        else
            if GetVehicleDoorAngleRatio(closestVehicle, door) > 0.0 then
                SetVehicleDoorShut(closestVehicle, door, false)
            else
                SetVehicleDoorOpen(closestVehicle, door, false, false)
            end
        end
    else
        ESX.ShowHelpNotification(traslatear("error.no_vehicle_found"), 'error', 2500)
    end
end)

RegisterNetEvent('qb-radialmenu:client:setExtra', function(data)
    local string = data.id
    local replace = string:gsub("extra", "")
    local extra = tonumber(replace)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped)
    if veh ~= nil then
        if GetPedInVehicleSeat(veh, -1) == ped then
            SetVehicleAutoRepairDisabled(veh, true) -- Forces Auto Repair off when Toggling Extra [GTA 5 Niche Issue]
            if DoesExtraExist(veh, extra) then
                if IsVehicleExtraTurnedOn(veh, extra) then
                    SetVehicleExtra(veh, extra, 1)
                    ESX.ShowHelpNotification(traslatear("error.extra_deactivated", {extra = extra}), 'error', 2500)
                else
                    SetVehicleExtra(veh, extra, 0)
                    ESX.ShowHelpNotification(traslatear("success.extra_activated", {extra = extra}), 'success', 2500)
                end
            else
                ESX.ShowHelpNotification(traslatear("error.extra_not_present", {extra = extra}), 'error', 2500)
            end
        else
            ESX.ShowHelpNotification(traslatear("error.not_driver"), 'error', 2500)
        end
    end
end)

RegisterNetEvent('qb-radialmenu:trunk:client:Door', function(plate, door, open)
    local veh = GetVehiclePedIsIn(PlayerPedId())
    if veh ~= 0 then
        local pl = QBCore.Functions.GetPlate(veh)
        if pl == plate then
            if open then
                SetVehicleDoorOpen(veh, door, false, false)
            else
                SetVehicleDoorShut(veh, door, false)
            end
        end
    end
end)

RegisterNetEvent('qb-radialmenu:client:ChangeSeat', function(data)
    local Veh = GetVehiclePedIsIn(PlayerPedId())
    local IsSeatFree = IsVehicleSeatFree(Veh, data.id)
    local speed = GetEntitySpeed(Veh)
    local HasHarnass = exports['qb-smallresources']:HasHarness()
    if not HasHarnass then
        local kmh = speed * 3.6
        if IsSeatFree then
            if kmh <= 100.0 then
                SetPedIntoVehicle(PlayerPedId(), Veh, data.id)
                ESX.ShowHelpNotification(traslatear("info.switched_seats", {seat = data.title}))
            else
                ESX.ShowHelpNotification(traslatear("error.vehicle_driving_fast"), 'error')
            end
        else
            ESX.ShowHelpNotification(traslatear("error.seat_occupied"), 'error')
        end
    else
        ESX.ShowHelpNotification(traslatear("error.race_harness_on"), 'error')
    end
end)

-- NUI Callbacks

RegisterNUICallback('closeRadial', function(data)
    setRadialState(false, false, data.delay)
end)

RegisterNUICallback('selectItem', function(data)
    local itemData = data.itemData
    local found, action = selectOption(FinalMenuItems, itemData)

    if itemData and found then
        if action then
            action(itemData)
        elseif itemData.type == 'client' then
            TriggerEvent(itemData.event, itemData)
        elseif itemData.type == 'server' then
            TriggerServerEvent(itemData.event, itemData)
        elseif itemData.type == 'command' then
            ExecuteCommand(itemData.event)
        elseif itemData.type == 'qbcommand' then
            TriggerServerEvent('QBCore:CallCommand', itemData.event, itemData)
        end
    end
end)

exports('AddOption', AddOption)
exports('RemoveOption', RemoveOption)
