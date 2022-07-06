local ESX = nil
local allMyCars = {}
local allOffres = {}
local carSelected = nil
local carSelectedB = nil
local priceSell = nil

Citizen.CreateThread(function()
    TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
	while ESX == nil do Citizen.Wait(100) end
end)

local function getAllCarsPlayer()
    ESX.TriggerServerCallback('rLeBonCoin:getAllMyCars', function(result)
        allMyCars = result
    end)
end

local function getAllCarsLeBonCoin()
    ESX.TriggerServerCallback('rLeBonCoin:getAllOffre', function(result)
        allOffres = result
    end)
end

local function lookCar(propsCar, myCoords)
    TriggerServerEvent("rLeBonCoin:setRoutingBucket", true)
    local car = propsCar.model
    RequestModel(car)
    while not HasModelLoaded(car) do
        RequestModel(car)
        Citizen.Wait(0)
    end
    local vehicle = CreateVehicle(car, Config.viewCarPos, false)
    ESX.Game.SetVehicleProperties(vehicle, propsCar)
    TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
    FreezeEntityPosition(vehicle, true)
    ESX.ShowNotification("~g~Vous avez 15 secondes")
    Wait(15000)
    SetEntityCoords(PlayerPedId(), myCoords)
    TriggerServerEvent("rLeBonCoin:setRoutingBucket", false)
end

local function rLeBonCoinKeyboard(TextEntry, ExampleText, MaxStringLenght)
    AddTextEntry('FMMC_KEY_TIP1', TextEntry)
    blockinput = true
    DisplayOnscreenKeyboard(1, "FMMC_KEY_TIP1", "", ExampleText, "", "", "", MaxStringLenght)
    while UpdateOnscreenKeyboard() ~= 1 and UpdateOnscreenKeyboard() ~= 2 do 
        Wait(0)
    end 
        
    if UpdateOnscreenKeyboard() ~= 2 then
        local result = GetOnscreenKeyboardResult()
        Wait(500)
        blockinput = false
        return result
    else
        Wait(500)
        blockinput = false
        return nil
    end
end


local function menuLeBonCoin()
    local menuP = RageUI.CreateMenu("Leboncoin", Config.subTitle)
    local menuS = RageUI.CreateSubMenu(menuP, "Espace client Leboncoin", Config.subTitle)
    local menuA = RageUI.CreateSubMenu(menuS, "Valider la publication", Config.subTitle)
    local menuB = RageUI.CreateSubMenu(menuP, "Leboncoin", Config.subTitle)
    local menuB2 = RageUI.CreateSubMenu(menuB, "Paiement", Config.subTitle)
    RageUI.Visible(menuP, not RageUI.Visible(menuP))
    while menuP do
        Citizen.Wait(0)

        RageUI.IsVisible(menuP, true, true, true, function()

            RageUI.Separator("~o~→→ Bienvenue sur Leboncoin")

            RageUI.ButtonWithStyle("~o~→→~s~ Mettre véhicule en vente",nil, {RightLabel = "→→→"}, true, function(Hovered, Active, Selected)
                if Selected then
                    getAllCarsPlayer()
                end
            end, menuS)

            RageUI.ButtonWithStyle("~o~→→~s~ Accéder à leboncoin",nil, {RightLabel = "→→→"}, true, function(Hovered, Active, Selected)
                if Selected then
                    getAllCarsLeBonCoin()
                end
            end, menuB)

        end)

        RageUI.IsVisible(menuS, true, true, true, function()

            if #allMyCars == 0 then
                RageUI.Separator("")
                RageUI.Separator("~r~Vous avez aucun véhicule a vendre")
                RageUI.Separator("")
            else
                RageUI.Separator("~o~→→ Veuillez choisir le véhicule a vendre")
                for k,v in pairs(allMyCars) do
                    local modelCar = v.vehicleProps.model
                    local nameModel = GetDisplayNameFromVehicleModel(modelCar)
                    local labelModel  = GetLabelText(nameModel)
                    RageUI.ButtonWithStyle("~o~→→~s~ "..labelModel,nil, {RightLabel = "→→→"}, true, function(Hovered, Active, Selected)
                        if Selected then
                            carSelected = v
                        end
                    end, menuA)
                end
            end

        end)

        RageUI.IsVisible(menuA, true, true, true, function()

            RageUI.Separator("~o~→→~s~ Model du véhicule : "..GetLabelText(GetDisplayNameFromVehicleModel(carSelected.vehicleProps.model)))
            if priceSell then
                RageUI.Separator("~o~→→~s~ Prix de vente : "..priceSell)
            else
                RageUI.Separator("~o~→→~s~ Prix de vente :")
            end

            RageUI.ButtonWithStyle("~o~→→~s~ Définir un prix",nil, {RightLabel = "→"}, true, function(Hovered, Active, Selected)
                if Selected then
                    local sellPrice = rLeBonCoinKeyboard("Prix de vente ?", "", 15)
                    if tonumber(sellPrice) then
                        priceSell = sellPrice
                    else
                        ESX.ShowNotification("~r~Une erreur lors de la définition du prix de vente")
                    end
                end
            end)

            RageUI.Separator("")

            RageUI.ButtonWithStyle("~o~→→~s~ ~g~Valider la mise en vente~s~",nil, {RightLabel = "→→→"}, true, function(Hovered, Active, Selected)
                if Selected then
                    if priceSell == nil then
                        ESX.ShowNotification("~r~Vous pouvez pas laisser les prix vide")
                    else
                        TriggerServerEvent("rLeBonCoin:upForSale", carSelected, priceSell)
                        priceSell = nil
                        carSelected = nil
                        RageUI.CloseAll()
                    end
                end
            end)

            RageUI.ButtonWithStyle("~o~→→~s~ ~r~Annuler la mise en vente~s~",nil, {RightLabel = "→→→"}, true, function(Hovered, Active, Selected)
                if Selected then
                    priceSell = nil
                    carSelected = nil
                    RageUI.CloseAll()
                end
            end)
        
        end)

        RageUI.IsVisible(menuB, true, true, true, function()

            if #allOffres == 0 then
                RageUI.Separator("")
                RageUI.Separator("~r~Aucune offre disponible")
                RageUI.Separator("")
            else
                RageUI.Separator("~o~→→ Voici les offres disponible")
                for k,v in pairs(allOffres) do
                    local modelCar = v.vehicleProps.model
                    local nameModel = GetDisplayNameFromVehicleModel(modelCar)
                    local labelModel  = GetLabelText(nameModel)
                    RageUI.ButtonWithStyle("~o~→→~s~ "..labelModel,nil, {RightLabel = "→→→"}, true, function(Hovered, Active, Selected)
                        if Selected then
                            carSelectedB = v
                        end
                    end, menuB2)
                end
            end
        end)

        RageUI.IsVisible(menuB2, true, true, true, function()

            RageUI.Separator("~o~→→~s~ Model du véhicule : "..GetLabelText(GetDisplayNameFromVehicleModel(carSelectedB.vehicleProps.model)))
            RageUI.Separator("~o~→→~s~ Prix de véhicule : "..carSelectedB.priceV)


            RageUI.ButtonWithStyle("~o~→→~s~ ~y~Voir le véhicule~s~",nil, {RightLabel = "→→→"}, true, function(Hovered, Active, Selected)
                if Selected then
                    lookCar(carSelectedB.vehicleProps, GetEntityCoords(PlayerPedId()))
                end
            end)

            RageUI.ButtonWithStyle("~o~→→~s~ ~g~Acheter ce véhicule~s~",nil, {RightLabel = "→→→"}, true, function(Hovered, Active, Selected)
                if Selected then
                    TriggerServerEvent("rLeBonCoin:buyCar", carSelectedB)
                    carSelectedB = nil
                    RageUI.CloseAll()
                end
            end)

            RageUI.ButtonWithStyle("~o~→→~s~ ~r~Annuler l'achat~s~",nil, {RightLabel = "→→→"}, true, function(Hovered, Active, Selected)
                if Selected then
                    carSelectedB = nil
                    RageUI.CloseAll()
                end
            end)
        
        end)

        if not RageUI.Visible(menuP) and not RageUI.Visible(menuS) and not RageUI.Visible(menuA) and not RageUI.Visible(menuB) and not RageUI.Visible(menuB2) then
            menuP = RMenu:DeleteType("menuP", true)
        end
    end
end


if Config.useLeBonCoinWithCommand then
    TriggerEvent('chat:addSuggestion', '/leboncoin', 'Accéder a leboncoin', {})
    RegisterCommand("leboncoin", function()
        menuLeBonCoin()
    end)
end


if Config.useLeBonCoinWithMarker then
    Citizen.CreateThread(function()
        local leboncoinBlip = AddBlipForCoord(Config.posLeBonCoin)
        SetBlipSprite(leboncoinBlip, 77)
        SetBlipColour(leboncoinBlip, 47)
        SetBlipScale(leboncoinBlip, 0.65)
        SetBlipAsShortRange(leboncoinBlip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString("LeBonCoin")
        EndTextCommandSetBlipName(leboncoinBlip)

        while true do
            local Timer = 500
            local plyPos = GetEntityCoords(PlayerPedId())
            local dist = #(plyPos-Config.posLeBonCoin)
            if dist <= 10.0 then
             Timer = 0
             DrawMarker(22, Config.posLeBonCoin, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 0.45, 0.45, 0.45, 255, 0, 0, 255, 55555, false, true, 2, false, false, false, false)
            end
             if dist <= 3.0 then
                Timer = 0
                    RageUI.Text({ message = "Appuyez sur ~y~[E]~s~ pour accéder a ~o~leboncoin~s~", time_display = 1 })
                if IsControlJustPressed(1,51) then
                    menuLeBonCoin()
                end
             end
        Citizen.Wait(Timer)
     end
    end)
end