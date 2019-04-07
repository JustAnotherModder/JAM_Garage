JAM_Garage = {}

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)	

function JAM_Garage:GetPlayerVehicles(identifier)	
	local playerVehicles = {}
	local data = MySQL.Sync.fetchAll("SELECT * FROM owned_vehicles WHERE owner=@identifier",{['@identifier'] = identifier})	
	for key,val in pairs(data) do
		local playerVehicle = json.decode(val.vehicle)
		table.insert(playerVehicles, {owner = val.owner, veh = val.vehicle, vehicle = playerVehicle, plate = val.plate, state = val.jamstate})
	end
	return playerVehicles
end

ESX.RegisterServerCallback('JAM_Garage:StoreVehicle', function(source, cb, vehicleProps)
	local isFound = false
	local xPlayer = ESX.GetPlayerFromId(source)

	if not xPlayer then return; end

	local playerVehicles = JAM_Garage:GetPlayerVehicles(xPlayer.getIdentifier())
	local plate = vehicleProps.plate

	for key,val in pairs(playerVehicles) do
		if(plate == val.plate) then
			local vehProps = json.encode(vehicleProps)
			MySQL.Sync.execute("UPDATE owned_vehicles SET vehicle=@vehProps WHERE plate=@plate",{['@vehProps'] = vehProps, ['@plate'] = val.plate})
			isFound = true
			break
		end
	end
	cb(isFound)
end)

ESX.RegisterServerCallback('JAM_Garage:GetVehicles', function(source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)

	if not xPlayer then return; end

	local vehicles = JAM_Garage:GetPlayerVehicles(xPlayer.getIdentifier())

	cb(vehicles)
end)

RegisterNetEvent('JAM_Garage:ChangeState')
AddEventHandler('JAM_Garage:ChangeState', function(plate, state)
	local xPlayer = ESX.GetPlayerFromId(source)

	if not xPlayer then return; end

	local vehicles = JAM_Garage:GetPlayerVehicles(xPlayer.getIdentifier())
	for key,val in pairs(vehicles) do
		if(plate == val.plate) then
			MySQL.Sync.execute("UPDATE owned_vehicles SET jamstate=@state WHERE plate=@plate",{['@state'] = state , ['@plate'] = plate})
			break
		end		
	end
end)

function JAM_Garage.Startup()
	local dbconfig  =
	{
	  	{ ["@dbtable@"] = "owned_vehicles", ["@dbfield@"] = "jamstate", ["@dbfieldconf@"] = "int(11) NOT NULL DEFAULT 0", },
	}

	local query1 = "SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE COLUMN_NAME='@dbfield@' and TABLE_NAME='@dbtable@';"
	local query2 = "ALTER TABLE `@dbtable@` ADD COLUMN `@dbfield@` @dbfieldconf@;"

	for _,c in pairs(dbconfig) do
		  local curquery1 = query1
		  local curquery2 = query2
		  for repThis,repWith in pairs(c) do curquery1 = curquery1:gsub(repThis,repWith); curquery2 = curquery2:gsub(repThis,repWith); end;
		  local data = MySQL.Sync.fetchAll( curquery1 )
		  if #data == 0 then  MySQL.Sync.fetchAll( curquery2 );  end;
	end
end

RegisterNetEvent('JAM_Garage:Startup')
AddEventHandler('JAM_Garage:Startup', JAM_Garage.Startup)