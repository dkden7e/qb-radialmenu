ESX = nil

TriggerEvent('esx:getSharedObject', function(obj)
	ESX = obj
end)

local trunkBusy = {}

RegisterNetEvent('qb-radialmenu:trunk:server:Door', function(open, plate, door)
    TriggerClientEvent('qb-radialmenu:trunk:client:Door', -1, plate, door, open)
end)

--RegisterNetEvent('qb-trunk:server:setTrunkBusy', function(plate, busy)
--    trunkBusy[plate] = busy
--end)
--
--RegisterNetEvent('qb-trunk:server:KidnapTrunk', function(targetId, closestVehicle)
--    TriggerClientEvent('qb-trunk:client:KidnapGetIn', targetId, closestVehicle)
--end)

--ESX.TriggerServerCallback('qb-trunk:server:getTrunkBusy', function(source, cb, plate)
--    if trunkBusy[plate] then cb(true) return end
--    cb(false)
--end)

--ESX.RegisterCommand("getintrunk", traslatear("general.getintrunk_command_desc"), {}, false, function(source)
--    TriggerClientEvent('qb-trunk:client:GetIn', source)
--end)

--ESX.RegisterCommand("putintrunk", traslatear("general.putintrunk_command_desc"), {}, false, function(source)
--    TriggerClientEvent('qb-trunk:server:KidnapTrunk', source)
--end)