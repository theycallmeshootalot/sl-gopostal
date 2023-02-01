local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = QBCore.Functions.GetPlayerData()

local hasAllBoxes = false
local isDoingJob = false
local hasDeliveredPackage = false

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then 
        PlayerJob = QBCore.Functions.GetPlayerData().job 
        GoPostalManager()
    end
end)

AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    PlayerJob = QBCore.Functions.GetPlayerData().job
    GoPostalManager()
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate')
AddEventHandler('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerJob = JobInfo
end)

CreateThread(function()
    local blip = AddBlipForCoord(133.8, 96.39, 83.51)
    SetBlipSprite(blip, 67)
    SetBlipColour(blip, 0)
    SetBlipScale(blip, 0.8)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("GoPostal Delivery Services")
    EndTextCommandSetBlipName(blip)
end)

AddEventHandler('onResourceStop', function(resourceName) 
	if GetCurrentResourceName() == resourceName then
        isDoingJob = false
        RemoveBlip(blip)
        exports['qb-radialmenu']:RemoveOption(radialmenu)
        exports['qb-radialmenu']:RemoveOption(radialmenued)
        exports['qb-target']:RemoveZone("houses")
	end 
end)


local function EnumerateEntitiesWithinDistance(entities, isPlayerEntities, coords, maxDistance) -- Used from qb-taxijob
	local nearbyEntities = {}
	if coords then
		coords = vector3(coords.x, coords.y, coords.z)
	else
		local playerPed = PlayerPedId()
		coords = GetEntityCoords(playerPed)
	end
	for k, entity in pairs(entities) do
		local distance = #(coords - GetEntityCoords(entity))
		if distance <= maxDistance then
			nearbyEntities[#nearbyEntities+1] = isPlayerEntities and k or entity
		end
	end
	return nearbyEntities
end

local function GetVehiclesInArea(coords, maxDistance) -- Used from qb-taxijob
	return EnumerateEntitiesWithinDistance(GetGamePool('CVehicle'), false, coords, maxDistance)
end

local function IsSpawnPointClear(coords, maxDistance) -- Used from qb-taxijob
	return #GetVehiclesInArea(coords, maxDistance) == 0
end

local function getVehicleSpawnPoint() -- Used from qb-taxijob
    local near = nil
	local distance = 50
    if IsSpawnPointClear(coords, 2.5) then
        local ped = PlayerPedId()
        local pos = GetEntityCoords(ped)
        local cur_distance = #(pos - coords)
        if cur_distance < distance then
            distance = cur_distance
            near = k
        end
    end
	return near
end

local function workVehicle() -- used from qb-taxijob
    local ped = PlayerPedId()
    local veh = GetEntityModel(GetVehiclePedIsIn(ped))
    local retval = false

    if veh == GetHashKey(Config.WorkVehicle) then
        retval = true
    end

    return retval
end

local function DrawText3D(x, y, z, text)
	SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x,y,z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0+0.0125, 0.017+ factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

RegisterNetEvent('sl-gopostal:client:apply', function()
    if PlayerJob.name == Config.JobName then
        QBCore.Functions.Notify('You already have the job.', 'error')
    else
        ClearPedTasksImmediately(PlayerPedId())
        TaskStartScenarioInPlace(PlayerPedId(), "WORLD_HUMAN_CLIPBOARD", 0, true)
        QBCore.Functions.Progressbar('gopostal_apply', 'Filling Out Documents', 5000, false, true, {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true,
        }, {}, {}, {}, function()
            TriggerServerEvent('sl-gopostal:server:apply')
            QBCore.Functions.Notify('You have been accepted to work at GoPostal Delivery Services.', 'success')
            ClearPedTasks(PlayerPedId())
        end, function()
            QBCore.Functions.Notify('You cancelled the process to apply for the GoPostal Delivery Services.', 'error')
            ClearPedTasks(PlayerPedId())
        end)
    end
end)

RegisterNetEvent('sl-gopostal:client:quit', function()
    ClearPedTasksImmediately(PlayerPedId())
    TaskStartScenarioInPlace(PlayerPedId(), "WORLD_HUMAN_CLIPBOARD", 0, true)

    QBCore.Functions.Progressbar('gopostal_quit', 'Quitting Job', 5000, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function()
        TriggerServerEvent('sl-gopostal:server:quit')
        QBCore.Functions.Notify('You successfully have left the GoPostal Team.', 'success')
        exports['qb-radialmenu']:RemoveOption(radialmenu)
        exports['qb-radialmenu']:RemoveOption(radialmenued)
        
        local hasAllBoxes = false
        local isDoingJob = false
        local hasDeliveredPackage = false
        ClearPedTasks(PlayerPedId())
    end, function()
        QBCore.Functions.Notify('You cancelled the process to quit the GoPostal job.', 'error')
        ClearPedTasks(PlayerPedId())
    end)
end)

function GoPostalManager()
    if not DoesEntityExist(amazonmodel) then

        RequestModel(Config.ManagerPed)
        while not HasModelLoaded(Config.ManagerPed) do
            Wait(0)
        end

        amazonmodel = CreatePed(1, Config.ManagerPed, Config.ManagerLocation.x, Config.ManagerLocation.y, Config.ManagerLocation.z, Config.ManagerLocation.w, false, false)
        SetEntityAsMissionEntity(amazonmodel)
        SetBlockingOfNonTemporaryEvents(amazonmodel, true)
        SetEntityInvincible(amazonmodel, true)
        FreezeEntityPosition(amazonmodel, true)
        TaskStartScenarioInPlace(amazonmodel, "WORLD_HUMAN_CLIPBOARD", 0, true)

        exports['qb-target']:AddTargetEntity(amazonmodel, {
            options = {
                {
                    type = "client",
                    event = "sl-gopostal:client:apply",
                    icon = "fa-solid fa-clipboard",
                    label = "Apply For Job",
                    canInteract = function()
                        if PlayerJob.name == Config.JobName then return false end 
                        return true 
                    end,
                },
                {
                    num = 1,
                    type = "client",
                    event = "sl-gopostal:client:requestwork",
                    icon = "fa-solid fa-truck",
                    label = "Request Work Vehicle",
                    job = Config.JobName,
                },
                {
                    num = 2,
                    type = "client",
                    event = "sl-gopostal:client:quit",
                    icon = "fa-solid fa-clipboard",
                    label = "Quit Job",
                    job = Config.JobName,
                }
            },
            distance = 2.5,
        })
    end
end

RegisterNetEvent('sl-gopostal:client:deliver', function()
    if QBCore.Functions.HasItem("box") then
        if isDoingJob == true then
            TriggerEvent('animations:client:EmoteCommandStart', {"box"})
            QBCore.Functions.Progressbar("leave_package", "Placing Package On The Ground", 5000, false, false, {
                disableMovement = true,
                disableCarMovement = true,
                disableMouse = false,
                disableCombat = true,
            }, {}, {}, {}, function()
                TriggerEvent('animations:client:EmoteCommandStart', {"mechanic"})
                QBCore.Functions.Progressbar("scan", "Scanning Package Barcode", 10000, false, false, {
                    disableMovement = true,
                    disableCarMovement = true,
                    disableMouse = false,
                    disableCombat = true,
                }, {}, {}, {}, function()
                    exports['qb-target']:RemoveZone("houses")
                    RemoveBlip(HouseBlip)
                    isDoingJob = false
                    TriggerServerEvent('sl-gopostal:server:removebox')
                    TriggerServerEvent('sl-gopostal:server:payment', work)
                end)
            end)
        end
    else
        QBCore.Functions.Notify("You do not have any packages in your inventory, go back to GoPostal Headquarters and get them at the loading dock", "error")
    end
end)

RegisterNetEvent("sl-gopostal:client:route", function()
    if QBCore.Functions.HasItem('box') then
        if isDoingJob == false then 
            isDoingJob = true
            work = Config.HouseLocations[math.random(1, #Config.HouseLocations)]
            QBCore.Functions.Notify("You have been given a new house location to deliver a package", "info")

            HouseBlip = AddBlipForCoord(work.x, work.y, work.z)
            SetBlipSprite(HouseBlip, 40)
            SetBlipColour(HouseBlip, 66)
            SetBlipRoute(HouseBlip, true)
            SetBlipRouteColour(HouseBlip, 66)
            SetBlipScale(HouseBlip, 0.9)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentSubstringPlayerName("House")
            EndTextCommandSetBlipName(HouseBlip)
            exports['qb-target']:AddCircleZone("houses", vector3(work.x, work.y, work.z), 1.4,{ 
                name = "houses", 
                debugPoly = true, 
                useZ=true, 
            }, { 
                options = { 
                    { 
                        type = "client", 
                        event = "sl-gopostal:client:deliver",
                        icon = "fa-solid fa-box", 
                        label = "Deliver Package", 
                        job = Config.JobName
                    }, 
                }, 
                distance = 2.5 })
        else
            QBCore.Functions.Notify("You have to end your current house delivery before getting a new location", "error")
        end
    else
        QBCore.Functions.Notify("You do not have any packages in your inventory, go back to GoPostal Headquarters and get them at the loading dock", "error")
    end
end)

RegisterNetEvent("sl-gopostal:client:endroute", function()
    if isDoingJob == true then 
        RemoveBlip(HouseBlip)
        isDoingJob = false
        QBCore.Functions.Notify("You have successfully ended your house delivery route", "info")
    else
        QBCore.Functions.Notify("You do not have an active house delivery", "error")
    end
end)

RegisterNetEvent("sl-gopostal:client:requestwork", function()
    if IsSpawnPointClear(coords, 2.0) then 
        QBCore.Functions.Notify("You have gotten your work vehicle, go to the loading dock and get packages.", "info")

        QBCore.Functions.TriggerCallback('QBCore:Server:SpawnVehicle', function(netId)
            local veh = NetToVeh(netId)
            SetVehicleNumberPlateText(veh, "WORK "..math.random(100,999))
            SetEntityAsMissionEntity(veh, true, true)
            TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(veh))
            SetVehicleEngineOn(veh, true, true)
            QBCore.Functions.GetPlate(veh)
            exports['LegacyFuel']:SetFuel(veh, 100.0)
        end, Config.WorkVehicle, Config.WorkVehicleSpawnCoords, true)

        CreateThread(function()
            while true do
                Wait(0)
                local position = GetEntityCoords(PlayerPedId())
                local distance = #(position - vector3(Config.LoadingDockLocation.x, Config.LoadingDockLocation.y, Config.LoadingDockLocation.z))
                if distance < 25 then
                    DrawMarker(2, 64.26, 124.87, 79.07, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.3, 0.5, 0.2, 200, 0, 0, 222, false, false, false, true, false, false, false)
                    if distance < 5 then
                        DrawText3D(64.26, 124.87, 79.35, "Press [E] to load packages into your vehicle")
                        if IsControlJustReleased(0, 38) then
                            if workVehicle() then 
                                if hasAllBoxes == false then
                                    SetEntityCoords(GetVehiclePedIsIn(PlayerPedId()), Config.LoadingDockLocation.x, Config.LoadingDockLocation.y, Config.LoadingDockLocation.z, false, false, false, true)
                                    SetEntityHeading(GetVehiclePedIsIn(PlayerPedId()), Config.LoadingDockLocation.w)

                                    QBCore.Functions.Progressbar('gopostal_packages', 'Grabbing Packages', 15000, false, true, {
                                        disableMovement = true,
                                        disableCarMovement = true,
                                        disableMouse = false,
                                        disableCombat = true,
                                    }, {}, {}, {}, function()
                                        ClearPedTasks(PlayerPedId())

                                        radialmenu = exports['qb-radialmenu']:AddOption({
                                            id = 'gopostal',
                                            title = 'Get House Location',
                                            icon = 'briefcase',
                                            type = 'client',
                                            event = 'sl-gopostal:client:route',
                                            shouldClose = true
                                        })

                                        radialmenued = exports['qb-radialmenu']:AddOption({
                                            id = 'gopostal',
                                            title = 'End Delivery',
                                            icon = 'briefcase',
                                            type = 'client',
                                            event = 'sl-gopostal:client:endroute',
                                            shouldClose = true
                                        })

                                        QBCore.Functions.Notify('You were given your packages, use your radial menu to get your delivery route', 'info')
                                        TriggerServerEvent('sl-gopostal:server:givebox')
                                        hasAllBoxes = true
                                    end, function()
                                        QBCore.Functions.Notify('You cancelled the process to receive packages into your vehicle', 'error')
                                        ClearPedTasks(PlayerPedId())
                                    end)
                                else
                                    QBCore.Functions.Notify("You already have the packages", "error")
                                end
                            else
                                QBCore.Functions.Notify('You are not in the provided vehicle authorized for work.', 'error', 7500)
                            end
                        end
                    end
                end
            end
        end)
    end
end)
