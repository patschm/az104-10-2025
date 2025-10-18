set file="%~dp0setup-backend-pools.bicep"
call az group create --name "network-gw-grp" --location "westeurope"
call az deployment group create -g "network-gw-grp" --template-file %file%

