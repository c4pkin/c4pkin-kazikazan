local framework = nil
local frameworkName = nil

Citizen.CreateThread(function()
    Wait(1000) 
    
    -- ESX 
    if GetResourceState('es_extended') == 'started' then
        if exports['es_extended'] then
            framework = exports['es_extended']:getSharedObject()
            if framework then
                frameworkName = 'esx'
                
                if framework.RegisterUsableItem then
                    framework.RegisterUsableItem('iphone', function(source) -- iphone test itemi özelleştirilebilir
                        TriggerClientEvent('esx:onUseItem', source, {name = 'iphone'}) -- iphone test itemi özelleştirilebilir
                    end)
                end
            end
        end
        if framework.RegisterUsableItem then
            framework.RegisterUsableItem('iphone', function(source) -- iphone test itemi özelleştirilebilir
                local xPlayer = framework.GetPlayerFromId(source)
                if xPlayer then
                    xPlayer.removeInventoryItem('iphone', 1)  -- iphone test itemi özelleştirilebilir
                end
                TriggerClientEvent('esx:onUseItem', source, {name = 'iphone'}) -- iphone test itemi özelleştirilebilir
            end)
        end        
    -- QBCore
    elseif GetResourceState('qb-core') == 'started' then
        framework = exports['qb-core']:GetCoreObject()
        if framework then
            frameworkName = 'qbcore'
            
            if framework.Functions and framework.Functions.CreateUseableItem then
                framework.Functions.CreateUseableItem('iphone', function(source) -- iphone test itemi özelleştirilebilir
                    TriggerClientEvent('inventory:client:UseItem', source, {name = 'iphone'})-- iphone test itemi özelleştirilebilir
                end)
            end
        end
    end
    if framework.Functions and framework.Functions.CreateUseableItem then
        framework.Functions.CreateUseableItem('iphone', function(source) -- iphone test itemi özelleştirilebilir
            local Player = framework.Functions.GetPlayer(source)
            if Player then
                Player.Functions.RemoveItem('iphone', 1) -- iphone test itemi özelleştirilebilir
            end
            TriggerClientEvent('inventory:client:UseItem', source, {name = 'iphone'}) -- iphone test itemi özelleştirilebilir
        end)
    end    
end)

-- Oyuncunun parası
RegisterServerEvent('c4pkin-kazikazan:getMoney')
AddEventHandler('c4pkin-kazikazan:getMoney', function()
    local _source = source
    local money = 0
    
    -- ESX
    if frameworkName == 'esx' and framework then
        local xPlayer = framework.GetPlayerFromId(_source)
        if xPlayer then
            money = xPlayer.getMoney()
        end
    -- QBCore
    elseif frameworkName == 'qbcore' and framework then
        local Player = framework.Functions.GetPlayer(_source)
        if Player and Player.PlayerData then
            money = Player.PlayerData.money.cash
        end
    else
        money = 5000
    end
    
    TriggerClientEvent('c4pkin-kazikazan:updateMoney', _source, money)
end)

-- Ödül kazanıldığında
RegisterServerEvent('c4pkin-kazikazan:prizeWon')
AddEventHandler('c4pkin-kazikazan:prizeWon', function(amount)
    local _source = source
    
    -- ESX 
    if frameworkName == 'esx' and framework then
        local xPlayer = framework.GetPlayerFromId(_source)
        if xPlayer then
            xPlayer.addMoney(amount)
        end
    -- QBCore
    elseif frameworkName == 'qbcore' and framework then
        local Player = framework.Functions.GetPlayer(_source)
        if Player then
            Player.Functions.AddMoney('cash', amount)
        end
    end
    
    Citizen.Wait(100) 
    TriggerEvent('c4pkin-kazikazan:getMoney')
end)

RegisterNetEvent("npcbuyer:buyPhone", function()
    local _source = source
    local price = Config.Price
    local item = Config.Item

    if frameworkName == 'esx' and framework then
        local xPlayer = framework.GetPlayerFromId(_source)
        if xPlayer then
            if xPlayer.getMoney() >= price then
                xPlayer.removeMoney(price)
                xPlayer.addInventoryItem(item, 1)
                TriggerClientEvent('esx:showNotification', _source, 'Kazı kazan satın alındı.')
            else
                TriggerClientEvent('esx:showNotification', _source, 'Yeterli paran yok!')
            end
        end
    elseif frameworkName == 'qbcore' and framework then
        local Player = framework.Functions.GetPlayer(_source)
        if Player then
            if Player.Functions.RemoveMoney('cash', price, "c4pkin-kazikazan") then
                Player.Functions.AddItem(item, 1)
                TriggerClientEvent('QBCore:Notify', _source, 'Kazı kazan satın alındı.', 'success')
            else
                TriggerClientEvent('QBCore:Notify', _source, 'Yeterli paran yok!', 'error')
            end
        end
    end

    Citizen.Wait(100)
    TriggerEvent('c4pkin-kazikazan:getMoney') 
end)