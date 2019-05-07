# JAM_Garage 
* Based off https://github.com/DanFrmSpace/esx_eden_garage
- A simple vMenu-style teleport-to-waypoint script.
- Default teleport key: "PAGEDOWN".
JAM_Garage gives your players a location to store their vehicles, along with an impound for whatever reason you might need that for. If the player leaves their vehicle unattended (log off or move out of render distance), the vehicle will automatically be placed back in the garage (unless it is the vehicle currently in-use). Damaged vehicle storage price and impound retrieval price can be set in the config.

### Requirements
* [EssentialMode](https://github.com/kanersps/essentialmode/releases)
* [EssentialMode Extended](https://github.com/ESX-Org/es_extended)
* [esx_vehicleshop](https://github.com/ESX-Org/esx_vehicleshop)
* [JAM-Base](https://github.com/JustAnotherModder/JAM)

## Download & Installation

### Manually
- Download https://github.com/JustAnotherModder/JAM_Garage/archive/master.zip
- Extract the JAM_Garage folder (and its contents) into your `JAM` folder, inside of your `resources` directory.
- Open `__resource.lua` in your `JAM` folder.
- Add the files to their respective locations, like so :

```
client_scripts {
	'JAM_Main.lua',
	'JAM_Client.lua',
	'JAM_Utilities.lua',

	-- Garage
	'JAM_Garage/JAM_Garage_Config.lua',
	'JAM_Garage/JAM_Garage_Client.lua',
}

server_scripts {	
	'JAM_Main.lua',
	'JAM_Server.lua',
	'JAM_Utilities.lua',

	-- MySQL
	'@mysql-async/lib/MySQL.lua',

	-- Garage
	'JAM_Garage/JAM_Garage_Config.lua',
	'JAM_Garage/JAM_Garage_Server.lua',
}
```

