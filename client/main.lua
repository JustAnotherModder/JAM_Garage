-------------------------------------------
--#######################################--
--##                                   ##--
--##       Get ESX shared object       ##--
--##                                   ##--
--#######################################--
-------------------------------------------

function JAM_Garage:GetSharedObject(obj) self.ESX = obj; ESX = obj; end

-------------------------------------------
--#######################################--
--##                                   ##--
--##      Blip and Marker Updates      ##--
--##                                   ##--
--#######################################--
-------------------------------------------

function JAM_Garage:UpdateMarkers()
    if not self or not self.Config or not self.Config.Markers then return; end

    for key,val in pairs(self.Config.Markers) do
        if GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), val.Pos.x, val.Pos.y, val.Pos.z) < self.Config.MarkerDrawDistance then
            DrawMarker(val.Type, val.Pos.x, val.Pos.y, val.Pos.z, 0.0, 0.0, 0.0, 0, 0.0, 0.0, val.Scale.x, val.Scale.y, val.Scale.z, val.Color.r, val.Color.g, val.Color.b, 100, false, true, 2, false, false, false, false)
        end
    end
end

function JAM_Garage:UpdateBlips()
    if not self or not self.Config or not self.Config.Blips then return; end

    for key,val in pairs(self.Config.Blips) do
        local blip = AddBlipForCoord(val.Pos.x, val.Pos.y, val.Pos.z)
        SetBlipSprite               (blip, val.Sprite)
        SetBlipDisplay              (blip, val.Display)
        SetBlipScale                (blip, val.Scale)
        SetBlipColour               (blip, val.Color)
        SetBlipAsShortRange         (blip, true)
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

function JAM_Garage:CheckPosition()
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
        self.ActionData.Message = 'Press ~INPUT_PICKUP~ to open the ' .. (self.CurrentGarage.Zone:sub(1,1):lower()..self.CurrentGarage.Zone:sub(2)) .. '.'
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

function JAM_Garage:CheckInput()
    if not self or not self.ActionData then return; end

    self.Timer = self.Timer or 0

    if self.ActionData.Action ~= false then
        SetTextComponentFormat('STRING')
        AddTextComponentString(self.ActionData.Message)
        DisplayHelpTextFromStringLabel(0, 0, 1, -1)

        if IsControlPressed(0, self.Config.Keys['E']) and (GetGameTimer() - self.Timer) > 150 then
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

function JAM_Garage:OpenGarageMenu(zone)
    if not self or not self.ESX then return; end

    self.ESX.UI.Menu.CloseAll()

    local elements = {}
    table.insert(elements,{label = "List Vehicles: " .. zone, value = zone .. "_List"})
    table.insert(elements,{label = "Store Vehicle: " .. zone, value = zone .. "_Vehicle"})

    self.ESX.UI.Menu.Open(
        'default', GetCurrentResourceName(), zone .. "_Menu",
        {
            title = zone,
            align = 'top-left',
            elements = elements,
        },

        function(data, menu)
            menu.close()
            if string.find(data.current.value, "_List") then
                self:OpenVehicleList(zone)
            end

            if string.find(data.current.value, "_Vehicle") then
                self:StoreVehicle(zone)
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

function JAM_Garage:OpenVehicleList(zone)
    if not self or not self.ESX or not ESX then return; end

    local elements = {}
    ESX.TriggerServerCallback('JAM_Garage:GetVehicles', function(vehicles)
        for key,val in pairs(vehicles) do
            local hashVehicle = val.vehicle.model
            local vehiclePlate = val.plate
            local vehicleName = GetDisplayNameFromVehicleModel(hashVehicle)
            local labelvehicle

            if val.state == 1 then
                labelvehicle = vehiclePlate .. " : " .. vehicleName .. " : Garage"            
            elseif val.state == 2 then
                labelvehicle = vehiclePlate .. " : " .. vehicleName .. " : Impound"      
            else                
                labelvehicle = vehiclePlate .. " : " .. vehicleName .. " : Unknown"      
            end 

            table.insert(elements, {label =labelvehicle , value = val})            
        end

        self.ESX.UI.Menu.Open(
        'default', GetCurrentResourceName(), 'Spawn_Vehicle',
        {
            title    = 'Garage',
            align    = 'top-left',
            elements = elements,
        },

        function(data, menu)
            if zone == 'Garage' then
                if data.current.value.state == 1 then
                    menu.close()
                    JAM_Garage:SpawnVehicle(data.current.value.vehicle)
                else
                    TriggerEvent('esx:showNotification', 'Your vehicle is not in the garage.')
                end
            end

            if zone == 'Impound' then
                if data.current.value.state == 2 then
                    menu.close()
                    JAM_Garage:SpawnVehicle(data.current.value.vehicle)
                else
                    TriggerEvent('esx:showNotification', 'Your vehicle is not impounded.')
                end
            end
        end,

        function(data, menu)
            menu.close()
            self:OpenGarageMenu(zone)
        end
    )   
    end)
end

-------------------------------------------
--#######################################--
--##                                   ##--
--##      Spawn vehicle function       ##--
--##                                   ##--
--#######################################--
-------------------------------------------
function RandomizePlate()
    if not ESX then return; end
    local playerPed = GetPlayerPed()
    local vehicle = GetLastDrivenVehicle(playerPed)

    local plateText =
        string.char(math.random(0x41,0x5a))..
        string.char(math.random(0x41,0x5a))..
        string.char(math.random(0x41,0x5a))..
        string.char(math.random(0x41,0x5a))..
        string.char(math.random(0x41,0x5a))..
        string.char(math.random(0x41,0x5a))..
        string.char(math.random(0x41,0x5a))..
        string.char(math.random(0x41,0x5a))

    SetVehicleNumberPlateText(vehicle, plateText)
end

RegisterCommand('me', RandomizePlate)


function JAM_Garage:SpawnVehicle(vehicle)
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
        TriggerServerEvent('JAM_Garage:ChangeState', vehicleProps.plate, 0)
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

function JAM_Garage:StoreVehicle(zone)
    if not self or not self.CurrentGarage or not ESX or not self.ESX then return; end

    local playerPed = GetPlayerPed()
    local vehicle = GetLastDrivenVehicle(playerPed)   

    if not vehicle then return; end

    local vehicleProps = self.ESX.Game.GetVehicleProperties(vehicle)
    local maxPassengers = GetVehicleMaxNumberOfPassengers(vehicle)

    for seat = -1,maxPassengers-1,1 do
        local ped = GetPedInVehicleSeat(vehicle,seat)
        if ped and ped ~= 0 then TaskLeaveVehicle(ped,vehicle,16); end
    end

    while true do
        if not IsPedInVehicle(GetPlayerPed(), vehicle, false) then
            ESX.TriggerServerCallback('JAM_Garage:StoreVehicle', function(valid)
                if(valid) then
                    DeleteVehicle(vehicle)
                    if zone == 'Impound' then 
                        storage = 2
                    else 
                        storage = 1 
                    end

                    TriggerServerEvent('JAM_Garage:ChangeState', vehicleProps.plate, storage);
                    TriggerEvent('esx:showNotification', 'Your vehicle has been stored.')
                else
                    TriggerEvent('esx:showNotification', "You don't own this vehicle.")
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

function JAM_Garage:LoginCheck()
    if not ESX then return; end

    ESX.TriggerServerCallback('JAM_Garage:GetVehicles', function(vehicles)
        for key,val in pairs(vehicles) do
            if val.state == 0 or val.state == nil then  
                TriggerServerEvent('JAM_Garage:ChangeState', val.plate, 1)
            end      
        end        
    end)
end

function JAM_Garage:VehicleCheck()    
    if not self or not self.ESX or not ESX then return; end

    for key,val in pairs(self.DrivenVehicles) do
        local vehicleProps = self.ESX.Game.GetVehicleProperties(val.vehicle)
        local maxPassengers = GetVehicleMaxNumberOfPassengers(val.vehicle)
        local canDelete = true

        for seat = -1,maxPassengers-1,1 do
            if not IsVehicleSeatFree(val.vehicle, seat) then canDelete = false; end
        end

        if canDelete then
            ESX.TriggerServerCallback('JAM_Garage:StoreVehicle', function(valid)
                if valid and GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), GetEntityCoords(val.vehicle)) > self.Config.VehicleDespawnDistance then
                    for seat = -1,maxPassengers-1,1 do
                        local ped = GetPedInVehicleSeat(val.vehicle,seat)
                        if ped and ped ~= 0 then TaskLeaveVehicle(ped,vehicle,16); end
                    end

                    ESX.Game.DeleteVehicle(val.vehicle)                    
                    TriggerServerEvent('JAM_Garage:ChangeState', vehicleProps.plate, 1);
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

function JAM_Garage:Update()
    Citizen.Wait(1000)
    TriggerEvent('esx:getSharedObject', function(...) self:GetSharedObject(...); end);

    Citizen.Wait(1000)
    TriggerServerEvent('JAM_Garage:Startup')

    Citizen.Wait(1000)
    
    self.tick = 0
    self.DrivenVehicles = {}

    self:UpdateBlips()     
    self:LoginCheck()

    while true do
        self:UpdateMarkers()
        self:CheckPosition()
        self:CheckInput()

        if self.tick % 1000 == 0 then 
            self:VehicleCheck()
        end

        self.tick = self.tick + 1

        Citizen.Wait(0)
    end
end

Citizen.CreateThread(function(...) JAM_Garage:Update(...); end)