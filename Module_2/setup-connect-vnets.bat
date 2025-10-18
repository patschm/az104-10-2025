set filewest="%~dp0setup_connect-vnets.bicep"
call az group create --name "network-WEU-grp" --location "westeurope"
call az deployment group create -g "network-WEU-grp" --template-file %filewest%

