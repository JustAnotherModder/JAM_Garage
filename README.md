# JAM_Garage 
* Based off https://github.com/DanFrmSpace/esx_eden_garage

JAM_Garage gives your players a location to store their vehicles, along with an impound for whatever reason you might need that for.
If the player leaves their vehicle unattended (log off or move out of render distance), the vehicle will automatically be placed back in the garage.

If you havn't already, you need to follow the guide at https://docs.fivem.net/server-manual/setting-up-a-server/ to setup a CitizenFX server. Once you've done that, you will need to follow the installation instructions found in each of the requirements below (and install and of their dependancies) before you use this mod.

### Requirements
* [EssentialMode](https://github.com/kanersps/essentialmode/releases)
* [EssentialMode Extended](https://github.com/ESX-Org/es_extended)
* [esx_vehicleshop](https://github.com/ESX-Org/esx_vehicleshop) (*For now...*)

## Download & Installation

### Manually
- Download https://github.com/bh-hub/blanchisseur/archive/master.zip
- Put it in the `resources` directory inside of your server folder.

## Installation
- Add this in your server.cfg :

```
start JAM_Garage
```

- Modify `config.lua@3:DBName` to your database name (the same one that your server.cfg uses)
