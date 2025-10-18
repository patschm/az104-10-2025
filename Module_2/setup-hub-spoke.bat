set filewest="%~dp0setup-hub-spokes.bicep"
call az deployment sub create -n "hub-spoke-depl" -l "westeurope" --template-file %filewest%