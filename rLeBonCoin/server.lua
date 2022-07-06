local ESX

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)


ESX.RegisterServerCallback('rLeBonCoin:getAllMyCars', function(source, cb)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    local myCars = {}
    MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @identifier', {
        ['@identifier'] = xPlayer.identifier,
    }, function(vehicles)
        for k,v in pairs(vehicles) do
            table.insert(myCars, {
                vehicleProps = json.decode(v.vehicle),
                plate = v.plate
            })
        end
        cb(myCars)
    end)
end)

ESX.RegisterServerCallback('rLeBonCoin:getAllOffre', function(source, cb)
    local allOffresD = {}
    MySQL.Async.fetchAll('SELECT * FROM leboncoin', {}, function(offres)
        for k,v in pairs(offres) do
            table.insert(allOffresD, {
                id = v.id,
                vehicleProps = json.decode(v.vehicle),
                plate = v.plate,
                priceV = v.price,
                owner = v.owner,
                date = v.date
            })
        end
        cb(allOffresD)
    end)
end)

local function getDate()
    return os.date("*t", os.time()).day.."/"..os.date("*t", os.time()).month.."/"..os.date("*t", os.time()).year.." à "..os.date("*t", os.time()).hour.."h"..os.date("*t", os.time()).min
end

RegisterNetEvent('rLeBonCoin:upForSale')
AddEventHandler('rLeBonCoin:upForSale', function(propsCar, priceSell)
	local _src = source
	local xPlayer = ESX.GetPlayerFromId(_src)
    TriggerClientEvent('esx:showNotification', _src, "~o~En cours de publication")
    MySQL.Async.execute('DELETE FROM owned_vehicles WHERE owner = @owner AND plate = @plate', {
        ['@owner'] = xPlayer.identifier,
        ['@plate'] = propsCar.plate
    }, function()
        MySQL.Async.execute('DELETE FROM open_car WHERE identifier = @identifier AND value = @value', {
            ['@identifier'] = xPlayer.identifier,
            ['@value'] = propsCar.plate
        }, function()
            MySQL.Async.execute('INSERT INTO leboncoin (vehicle, plate, price, owner, date) VALUES (@vehicle, @plate, @price, @owner, @date)', {
                ['@vehicle'] = json.encode(propsCar.vehicleProps),
                ['@plate'] = propsCar.plate,
                ['@price'] = priceSell,
                ['@owner'] = xPlayer.identifier,
                ['@date'] = getDate(),
            }, function()
                TriggerClientEvent('esx:showNotification', _src, "~g~Votre publication a été mis en ligne")
            end)
        end)
    end)
end)


RegisterNetEvent('rLeBonCoin:buyCar')
AddEventHandler('rLeBonCoin:buyCar', function(infoA)
	local _src = source
	local xPlayer = ESX.GetPlayerFromId(_src)
    local getMoney = xPlayer.getMoney()
    if getMoney >= tonumber(infoA.priceV) then
        MySQL.Async.execute('DELETE FROM leboncoin WHERE id = @id', {
            ['@id'] = infoA.id
        }, function()
            MySQL.Async.execute('INSERT INTO owned_vehicles (owner, plate, vehicle, type, stored) VALUES (@owner, @plate, @vehicle, @type, @stored)', {
                ['@owner'] = xPlayer.identifier,
                ['@plate'] = infoA.plate,
                ['@vehicle'] = json.encode(infoA.vehicleProps),
                ['@type'] = "car",
                ['@stored'] = true,
            }, function()
                xPlayer.removeAccountMoney('bank', tonumber(infoA.priceV))
                TriggerClientEvent('esx:showNotification', _src, "~g~Vous avez reçu votre véhicule, il vous attend dans votre garage")
                local xTarget = ESX.GetPlayerFromIdentifier(infoA.owner)
                if xTarget then
                    TriggerClientEvent('esx:showNotification', _src, "vous avez vendu votre véhicule (~g~+ "..infoA.priceV.."~s~)")
                    xTarget.addAccountMoney('bank', tonumber(infoA.priceV))
                else
                    if Config.legacy then
                        MySQL.Async.execute("SELECT accounts FROM users WHERE identifier = @identifier", {['@identifier'] = infoA.owner}, function(result)
                            if result[1] then
                                local accounts = json.decode(result[1].accounts)
                                accounts.bank = accounts.bank + infoA.priceV
                                MySQL.Async.execute("UPDATE users SET accounts = @accounts WHERE identifier = @identifier", {['@accounts'] = json.encode(accounts), ['@identifier'] = infoA.owner})
                            end
                        end)
                    else
                        MySQL.Async.execute("SELECT bank FROM users WHERE identifier = @identifier", {['@identifier'] = infoA.owner}, function(result)
                            if result[1] then
                                MySQL.Async.execute("UPDATE users SET bank = @bank WHERE identifier = @identifier", {['@bank'] = result[1].bank + infoA.priceV, ['@identifier'] = infoA.owner})
                            end
                        end)
                    end
                end
            end)
        end)
    else
        TriggerClientEvent('esx:showNotification', _src, "~r~Vous avez pas assez d'argent")
    end
end)

RegisterServerEvent("rLeBonCoin:setRoutingBucket")
AddEventHandler("rLeBonCoin:setRoutingBucket", function(enter)
    local _src = source
    if enter then
        SetPlayerRoutingBucket(_src, (78456561+_src))
    else
        SetPlayerRoutingBucket(_src, 0)
    end
end)