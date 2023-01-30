local QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('sl-gopostal:server:apply', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if #(GetEntityCoords(GetPlayerPed(src)) - vector3(Config.ManagerLocation.x, Config.ManagerLocation.y, Config.ManagerLocation.z)) < 3 then 
        if Player.PlayerData.job.name ~= Config.JobName then
            Player.Functions.SetJob(Config.JobName, 0)
        end
    else
        TriggerEvent('qb-log:server:CreateLog', 'anticheat', 'sl-gopostal', 'red', '**FiveM Identifier**: `'..GetPlayerName(src) .. '` \n**Character Name**: `'..Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname ..'`\n**CSN**: `'..Player.PlayerData.citizenid..'`\n**ID**: `'..src..'`\n**License**: `'..Player.PlayerData.license.."`\n\n **Detection of an event being triggered for attempting to set the players job to `"..Config.JobName.."` whilst this player being out of range**", true)
        DropPlayer(src, "You were removed for the detection of cheating (sl-gopostal), if you believe this was a mistake contact Server Administration.")
    end
end)

RegisterNetEvent('sl-gopostal:server:quit', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if #(GetEntityCoords(GetPlayerPed(src)) - vector3(Config.ManagerLocation.x, Config.ManagerLocation.y, Config.ManagerLocation.z)) < 3 then 
        if Player.PlayerData.job.name == Config.JobName then
            Player.Functions.SetJob(Config.CivilianJobName, 0)
        end
    else
        TriggerEvent('qb-log:server:CreateLog', 'anticheat', 'sl-gopostal', 'red', '**FiveM Identifier**: `'..GetPlayerName(src) .. '` \n**Character Name**: `'..Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname ..'`\n**CSN**: `'..Player.PlayerData.citizenid..'`\n**ID**: `'..src..'`\n**License**: `'..Player.PlayerData.license.."`\n\n **Detection of an event being triggered for attempting to remove the players job from `"..Config.JobName.."` to `"..Config.CivilianJobName.."` whilst this player being out of range**", true)
        DropPlayer(src, "You were removed for the detection of cheating (sl-gopostal), if you believe this was a mistake contact Server Administration.")
    end
end)

RegisterNetEvent('sl-gopostal:server:givebox', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if Player.PlayerData.job.name == Config.JobName then
        Player.Functions.AddItem(Config.PackageItem, Config.PackageItemAmount, false)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.PackageItem], "add")
    else
        TriggerEvent('qb-log:server:CreateLog', 'anticheat', 'sl-gopostal', 'red', '**FiveM Identifier**: `'..GetPlayerName(src) .. '` \n**Character Name**: `'..Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname ..'`\n**CSN**: `'..Player.PlayerData.citizenid..'`\n**ID**: `'..src..'`\n**License**: `'..Player.PlayerData.license.."`\n\n **Detection of an event being triggered for attempting to add `"..Config.PackageItem.."` to their inventory without having the `"..Config.JobName.."` job **", true)
        DropPlayer(src, "You were removed for the detection of cheating (sl-gopostal), if you believe this was a mistake contact Server Administration.")
    end
end)

RegisterNetEvent('sl-gopostal:server:removebox', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if Player.PlayerData.job.name == Config.JobName then
        Player.Functions.RemoveItem(Config.PackageItem, 1, false)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.PackageItem], "remove")
    else
        TriggerEvent('qb-log:server:CreateLog', 'anticheat', 'sl-gopostal', 'red', '**FiveM Identifier**: `'..GetPlayerName(src) .. '` \n**Character Name**: `'..Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname ..'`\n**CSN**: `'..Player.PlayerData.citizenid..'`\n**ID**: `'..src..'`\n**License**: `'..Player.PlayerData.license.."`\n\n **Detection of an event being triggered for attempting to remove `"..Config.PackageItem.."` from their inventory without having the `"..Config.JobName.."` job **", true)
        DropPlayer(src, "You were removed for the detection of cheating (sl-gopostal), if you believe this was a mistake contact Server Administration.")
    end
end)

RegisterNetEvent('sl-gopostal:server:payment', function(work)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local amount = math.random(Config.MinimumPayment, Config.MaximumPayment)
    local tipamount = math.random(Config.TipsMinimumPayment, Config.TipsMaximumPayment)
    local chance = math.random(0, 100)
    coords = work

    if #(GetEntityCoords(GetPlayerPed(src)) - coords) < 3 then 
        if Player.PlayerData.job.name == Config.JobName then
            Player.Functions.AddMoney("bank", amount, "gopostal-payment")
            TriggerClientEvent('QBCore:Notify', src, "You were payed $" ..amount.. " for delivering a package", 'info')

            if chance < 25 then 
                Player.Functions.AddMoney("cash", tipamount, "gopostal-tip-payment")
                TriggerClientEvent('QBCore:Notify', src, "The home owner tipped you $" ..tipamount.. " for your services", 'info')
            end
        end
    else
        TriggerEvent('qb-log:server:CreateLog', 'anticheat', 'sl-gopostal', 'red', '**FiveM Identifier**: `'..GetPlayerName(src) .. '` \n**Character Name**: `'..Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname ..'`\n**CSN**: `'..Player.PlayerData.citizenid..'`\n**ID**: `'..src..'`\n**License**: `'..Player.PlayerData.license.."`\n\n **Detection of an event being triggered for attempting to give the player money with the amount of `$"..amount.."` whilst this player being out of range of a house location or without having `"..Config.JobName.."`**", true)
        DropPlayer(src, "You were removed for the suspicion of cheating (sl-gopostal). If this is a mistake, contact server administration.")
    end
end)
