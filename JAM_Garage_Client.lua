local JAG = JAM.Garage
-------------------------------------------
--#######################################--
--##                                   ##--
--##      Blip and Marker Updates      ##--
--##                                   ##--
--#######################################--
-------------------------------------------

function JAG:UpdateMarkers()
    if not self or not self.Config or not self.Config.Markers then return; end

    for key,val in pairs(self.Config.Markers) do
        if GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), val.Pos.x, val.Pos.y, val.Pos.z) < self.Config.MarkerDrawDistance then
            DrawMarker(val.Type, val.Pos.x, val.Pos.y, val.Pos.z, 0.0, 0.0, 0.0, 0, 0.0, 0.0, val.Scale.x, val.Scale.y, val.Scale.z, val.Color.r, val.Color.g, val.Color.b, 100, false, true, 2, false, false, false, false)
        end
    end
end

function JAG:SetBlips()
    if not self or not self.Config or not self.Config.Blips then return; end

    for key,val in pairs(self.Config.Blips) do
        local blip = AddBlipForCoord(val.Pos.x, val.Pos.y, val.Pos.z)
        SetBlipSprite               (blip, val.Sprite)
        SetBlipDisplay              (blip, val.Display)
        SetBlipScale                (blip, val.Scale)
        SetBlipColour               (blip, val.Color)
        SetBlipAsShortRange         (blip, true)
        SetBlipHighDetail           (blip, true)
        BeginTextCommandSetBlipName ("STRING")
        AddTextComponentString      (val.Zone)
        EndTextCommandSetBlipName   (blip)
    end
end

-------------------------------------------
--#######################################--
--##                                   ##--
--##       Check player position       ##--
--##        relevant to markers        ##--
--##                                   ##--
--#######################################--
-------------------------------------------

function JAG:CheckPosition()
    if not self or not self.Config or not self.Config.Markers then return; end

    self.StandingInMarker = self.StandingInMarker or false
    self.CurrentGarage = self.CurrentGarage or {}

    local standingInMarker = false

    for key,val in pairs(self.Config.Markers) do
        if GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), val.Pos.x, val.Pos.y, val.Pos.z) < val.Scale.x then
            self.CurrentGarage = val
            standingInMarker = true
        end
    end

    if standingInMarker and not self.StandingInMarker then
        self.StandingInMarker = true
        self.ActionData = ActionData or {};
        self.ActionData.Action = self.CurrentGarage.Zone            
        self.ActionData.Message = 'Press ~INPUT_PICKUP~ to open the ~b~' .. (self.CurrentGarage.Zone:sub(1,1):lower()..self.CurrentGarage.Zone:sub(2)) .. '~s~.'
    end

    if not standingInMarker and self.StandingInMarker then
        self.StandingInMarker = false
        self.ActionData.Action = false
        self.ESX.UI.Menu.CloseAll()
    end
end

-------------------------------------------
--#######################################--
--##                                   ##--
--##        Check for input if         ##--
--##           inside marker           ##--
--##                                   ##--
--#######################################--
-------------------------------------------

function JAG:CheckInput()
    if not self or not self.ActionData then return; end

    self.Timer = self.Timer or 0

    if self.ActionData.Action ~= false then
        SetTextComponentFormat('STRING')
        AddTextComponentString(self.ActionData.Message)
        DisplayHelpTextFromStringLabel(0, 0, 1, -1)

        if IsControlPressed(0, JUtils.Keys['E']) and (GetGameTimer() - self.Timer) > 150 then
            self:OpenGarageMenu(self.ActionData.Action)
            self.ActionData.Action = false
            self.Timer = GetGameTimer()
        end
    end
end

-------------------------------------------
--#######################################--
--##                                   ##--
--##            Garage Menu            ##--
--##                                   ##--
--#######################################--
-------------------------------------------

function JAG:OpenGarageMenu(zone)
    if not self or not self.ESX or not self.Config then return; end

    self.ESX.UI.Menu.CloseAll()

    local elements = {}
    local price = 0

    if zone == 'Impound' and self.Config.ImpoundCost > 0 then str = zone .. ' - $' .. self.Config.ImpoundCost
    else
        if self.Config.RepairCost > 0 then
            local playerPed = GetPlayerPed(PlayerId())
            
            local vehicle = GetLastDrivenVehicle(playerPed)   
            if vehicle then
                local vehHealth = (GetVehicleBodyHealth(vehicle) / 10)           -- 0 - 100
                local dmg = 0

                while dmg + vehHealth < 100 do
                    dmg = dmg + 1
                    Citizen.Wait(0)
                end

                if dmg > 0 then
                    price = math.floor((self.Config.RepairCost / 100) * dmg)   -- percententage based on vehHealth
                    str = zone .. ' - $' .. price
                else str = zone; end
            else str = zone; end
        else str = zone; end
    end

    if price and price > 0 then labelStr = "Store Vehicle : $" .. price
    else labelStr = "Store Vehicle"; end

    table.insert(elements,{label = "List Vehicles", value = zone .. "_List"})
    table.insert(elements,{label = labelStr, value = zone .. "_Vehicle"})

    self.ESX.UI.Menu.Open(
        'default', GetCurrentResourceName(), zone .. '_Menu',
        {
            title = str,
            align = 'top-left',
            elements = elements,
        },

        function(data, menu)
            menu.close()
            if string.find(data.current.value, "_List") then
                self:OpenVehicleList(zone)
            end

            if string.find(data.current.value, "_Vehicle") then
                self:StoreVehicle(zone, price)
            end
        end,
        function(data, menu)
            menu.close()
            self.ActionData.Action = self.CurrentGarage.Zone  
        end
    )
end

-------------------------------------------
--#######################################--
--##                                   ##--
--##         Vehicle List Menu         ##--
--##                                   ##--
--#######################################--
-------------------------------------------

function JAG:OpenVehicleList(zone)
    if not self or not self.ESX or not ESX then return; end

    self.ESX.UI.Menu.CloseAll()
    local elements = {}
    ESX.TriggerServerCallback('JAG:GetVehicles', function(vehicles)
        for key,val in pairs(vehicles) do
            local hashVehicle = val.vehicle.model
            local vehiclePlate = val.plate
            local vehicleName = GetDisplayNameFromVehicleModel(hashVehicle)
            local labelvehicle

            if val.state == 1 then
                labelvehicle = '<span style="font-weight:bold;">' .. vehicleName .. ' </span>: ' .. vehiclePlate .. ' : <span style="font-weight:bold;color:green;">Garage</span>'            
            elseif val.state == 2 then
                labelvehicle = '<span style="font-weight:bold;">' .. vehicleName .. ' </span>: ' .. vehiclePlate .. ' : <span style="font-weight:bold;color:orange;">Impound</span>'      
            else                
                labelvehicle = '<span style="font-weight:bold;">' .. vehicleName .. ' </span>: ' .. vehiclePlate .. ' : <span style="font-weight:bold;color:red;">Unknown</span>'      
            end 

            table.insert(elements, {label =labelvehicle , value = val})                      
        end
        self:LoadVehicles(vehicles)
        self.ESX.UI.Menu.Open(
        'default', GetCurrentResourceName(), 'Spawn_Vehicle',
        {
            title    = zone,
            align    = 'top-left',
            elements = elements,
        },

        function(data, menu)
            if zone == 'Garage' then
                if data.current.value.state == 1 then
                    menu.close()
                    JAG:SpawnVehicle(data.current.value.vehicle, zone)
                else
                    TriggerEvent('esx:showNotification', 'Your vehicle ~r~is not in the garage.~s~')
                end
            end

            if zone == 'Impound' then
                if data.current.value.state == 2 then
                    local playerData = ESX.GetPlayerData()
                    if playerData.money >= self.Config.ImpoundCost then
                        JAG:SpawnVehicle(data.current.value.vehicle, zone)
                    else
                        TriggerEvent('esx:showNotification', "You ~r~don't have enough money.~s~")
                    end
                    menu.close()
                else
                    TriggerEvent('esx:showNotification', 'Your vehicle ~r~is not impounded.~s~')
                end
            end            
            self:UnloadVehicles(vehicles)
        end,

        function(data, menu)
            menu.close()
            self:UnloadVehicles(vehicles)
            self:OpenGarageMenu(zone)
        end
    )   
    end)
end

function JAG:LoadVehicles(vehicles)
    for k,v in pairs(vehicles) do
        while not HasModelLoaded(v.vehicle.model) do
            RequestModel(v.vehicle.model)
            Citizen.Wait(0)
        end
    end
end

function JAG:UnloadVehicles(vehicles)
    for k,v in pairs(vehicles) do
        if HasModelLoaded(v.vehicle.model) then
            SetModelAsNoLongerNeeded(v.vehicle.model)
        end
    end
end
-------------------------------------------
--#######################################--
--##                                   ##--
--##      Spawn vehicle function       ##--
--##                                   ##--
--#######################################--
-------------------------------------------
function JAG:SpawnVehicle(vehicle, zone)
    if not self or not self.ESX or not ESX then return; end
    self.DrivenVehicles = self.DrivenVehicles or {}

    ESX.Game.SpawnVehicle(vehicle.model,{
        x=self.CurrentGarage.Pos.x,
        y=self.CurrentGarage.Pos.y,
        z=self.CurrentGarage.Pos.z + 1,                                         
        },self.CurrentGarage.Heading, function(callback_vehicle)
        self.ESX.Game.SetVehicleProperties(callback_vehicle, vehicle)
        SetVehRadioStation(callback_vehicle, "OFF")

        TaskWarpPedIntoVehicle(GetPlayerPed(-1), callback_vehicle, -1)
        table.insert(self.DrivenVehicles, {vehicle = callback_vehicle})

        local vehicleId GetVehiclePedIsUsing(GetPlayerPed(-1))
        SetEntityAsMissionEntity(GetVehicleAttachedToEntity(vehicleId), true, true)

        local vehicleProps = self.ESX.Game.GetVehicleProperties(callback_vehicle)
        TriggerServerEvent('JAG:ChangeState', vehicleProps.plate, 0)
        if zone == 'Impound' then TriggerServerEvent('JAG:FinePlayer', self.Config.ImpoundCost); end
        self.ActionData.Action = self.CurrentGarage.Zone  
    end) 
end

-------------------------------------------
--#######################################--
--##                                   ##--
--##      Store vehicle function       ##--
--##                                   ##--
--#######################################--
-------------------------------------------

function JAG:StoreVehicle(zone, price)
    if not self or not self.CurrentGarage or not ESX or not self.ESX then return; end

    local playerPed = GetPlayerPed(PlayerId())
    local vehicle = GetLastDrivenVehicle(playerPed)   

    if not vehicle then return; end

    if price and price > 0 then
        local playerData = ESX.GetPlayerData()
        if playerData.money and playerData.money > price then
            TriggerServerEvent('JAG:FinePlayer', price)
        else return; end
    end

    local vehicleProps = self.ESX.Game.GetVehicleProperties(vehicle)
    local maxPassengers = GetVehicleMaxNumberOfPassengers(vehicle)

    for seat = -1,maxPassengers-1,1 do
        local ped = GetPedInVehicleSeat(vehicle,seat)
        if ped and ped ~= 0 then TaskLeaveVehicle(ped,vehicle,16); end
    end

    while true do
        if not IsPedInVehicle(GetPlayerPed(PlayerId()), vehicle, false) then
            ESX.TriggerServerCallback('JAG:StoreVehicle', function(valid)
                if(valid) then
                    DeleteVehicle(vehicle)
                    if zone == 'Impound' then 
                        storage = 2
                    else 
                        storage = 1 
                    end

                    TriggerServerEvent('JAG:ChangeState', vehicleProps.plate, storage);
                    TriggerEvent('esx:showNotification', 'Your vehicle ~g~has been stored.~s~')
                else
                    TriggerEvent('esx:showNotification', "~r~You don't own this vehicle.~s~")
                end
            end, vehicleProps)

            self.ActionData.Action = self.CurrentGarage.Zone  
            break
        end

        Citizen.Wait(0)      
    end
end

-------------------------------------------
--#######################################--
--##                                   ##--
--##      Vehicle Check Function       ##--
--##     This automatically sends      ##--
--##    vehicles back to the garage    ##--
--##      when they are likely to      ##--
--##       be trapped in "limbo"       ##--
--##                                   ##--
--#######################################--
-------------------------------------------

function JAG:LoginCheck()
    if not ESX then return; end
    ESX.TriggerServerCallback('JAG:GetVehicles', function(vehicles)
        for key,val in pairs(vehicles) do
            if val.state == 0 or val.state == nil then  
                TriggerServerEvent('JAG:ChangeState', val.plate, 1)
            end      
        end        
    end)
end

function JAG:VehicleCheck()    
    if not self or not self.ESX or not ESX then return; end
    self.DrivenVehicles = self.DrivenVehicles or {}
    for key,val in pairs(self.DrivenVehicles) do
        local canDelete = true
        local vehicleProps = self.ESX.Game.GetVehicleProperties(val.vehicle)
        local maxPassengers = GetVehicleMaxNumberOfPassengers(val.vehicle)

        for k,v in pairs(val) do 
            if v == GetLastDrivenVehicle(PlayerPedId(), 0) then 
                canDelete = false 
            end 
        end
        
        for seat = -1,maxPassengers-1,1 do
            if not IsVehicleSeatFree(val.vehicle, seat) then canDelete = false; end
        end

        if canDelete then
            ESX.TriggerServerCallback('JAG:StoreVehicle', function(valid)
                if valid and GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), GetEntityCoords(val.vehicle)) > self.Config.VehicleDespawnDistance then
                    ESX.Game.DeleteVehicle(val.vehicle)                    
                    TriggerServerEvent('JAG:ChangeState', vehicleProps.plate, 1);
                end
            end, vehicleProps)
        end
    end
end

-------------------------------------------
--#######################################--
--##                                   ##--
--##        Garage Update Thread       ##--
--##                                   ##--
--#######################################--
-------------------------------------------

function JAG:Start()
    if not self then return; end
    if not ESX then 
        while not ESX do Citizen.Wait(100); end
        self.ESX = ESX
    end

    while not ESX.IsPlayerLoaded() do Citizen.Wait(100); end
    TriggerServerEvent('JAG:Startup') 

    self:LoginCheck() 

    self:SetBlips()   

    self:Update() 
end

function JAG:Update()  
    if not self then return; end
    while true do        
        self.tick = (self.tick or 0) + 1
        self:UpdateMarkers()
        self:CheckInput()

        if self.tick % 100 == 1 then
            self:CheckPosition()
        end
        
        if self.tick % 1000 == 1 then 
            self:VehicleCheck()
        end

        Citizen.Wait(0)
    end
end

Citizen.CreateThread(function(...) JAG:Start(...); end)
