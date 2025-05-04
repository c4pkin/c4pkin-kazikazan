local display = false
local framework = nil
local frameworkName = nil

Citizen.CreateThread(function()
    Wait(1000) 
    
    if GetResourceState('es_extended') == 'started' then
        -- ESX 
        TriggerEvent('esx:getSharedObject', function(obj) framework = obj end)
        if framework then
            frameworkName = 'esx'
        end
    elseif GetResourceState('qb-core') == 'started' then
        -- QBCore 
        framework = exports['qb-core']:GetCoreObject()
        if framework then
            frameworkName = 'qbcore'
        end
    end
end)

function SetDisplay(bool)
    display = bool
    SetNuiFocus(bool, bool)
    if bool then

        TriggerServerEvent('c4pkin-kazikazan:getMoney')
        
        SendNUIMessage({
            type = "OPEN_SCRATCH_CARD",
            money = 0 
        })
    else
        SendNUIMessage({
            type = "CLOSE_SCRATCH_CARD"
        })
    end
end

RegisterNetEvent('c4pkin-kazikazan:updateMoney')
AddEventHandler('c4pkin-kazikazan:updateMoney', function(money)
    SendNUIMessage({
        type = "UPDATE_MONEY",
        money = money
    })
end)

-- ESX 
if GetResourceState('es_extended') == 'started' then
    Citizen.CreateThread(function()
        while framework == nil do
            Wait(100)
        end
        
        RegisterNetEvent('esx:onUseItem')
        AddEventHandler('esx:onUseItem', function(item)
            if item.name == 'iphone' then -- item.name = iphone test itemi özelleştirilebilir
                SetDisplay(true)
            end
        end)
    end)
end

-- QBCore
if GetResourceState('qb-core') == 'started' then
    Citizen.CreateThread(function()
        while framework == nil do
            Wait(100)
        end
        
        RegisterNetEvent('inventory:client:UseItem')
        AddEventHandler('inventory:client:UseItem', function(item)
            if item.name == 'iphone' then -- item.name = iphone test itemi özelleştirilebilir
                SetDisplay(true)
            end
        end)
    end)
end

function ShowNotification(message)
    if frameworkName == 'esx' and framework.ShowNotification then
        framework.ShowNotification(message)
    elseif frameworkName == 'qbcore' and framework.Functions.Notify then
        framework.Functions.Notify(message)
    else
        SetNotificationTextEntry("STRING")
        AddTextComponentString(message)
        DrawNotification(false, false)
    end
end

RegisterNUICallback('close', function(data, cb)
    SetDisplay(false)
    cb('ok')
end)

RegisterNUICallback('prizeWon', function(data, cb)
    local amount = data.amount
    
    TriggerServerEvent('c4pkin-kazikazan:prizeWon', amount)
    
    ShowNotification("Tebrikler! $" .. amount .. " kazandınız!")
    cb('ok')
end)

RegisterNUICallback('showNotification', function(data, cb)
    ShowNotification(data.message)
    cb('ok')
end)

CreateThread(function()
    for i, npc in pairs(Config.Shops) do
        RequestModel(npc.model)
        while not HasModelLoaded(npc.model) do Wait(0) end

        local ped = CreatePed(0, npc.model, npc.coords.x, npc.coords.y, npc.coords.z - 1, npc.coords.w, false, false)
        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)

        exports['qb-target']:AddTargetEntity(ped, {
            options = {
                {
                    label = "Bilet Satıcısı ile Konuş ($500)",
                    icon = "fas fa-store",
                    action = function()
                        TriggerServerEvent("npcbuyer:buyPhone")
                    end
                }
            },
            distance = 2.5,
        })

        if npc.blip.enabled then
            local blip = AddBlipForCoord(npc.coords.x, npc.coords.y, npc.coords.z)
            SetBlipSprite(blip, npc.blip.sprite)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, npc.blip.scale)
            SetBlipColour(blip, npc.blip.color)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(npc.blip.label)
            EndTextCommandSetBlipName(blip)
        end
    end
end)