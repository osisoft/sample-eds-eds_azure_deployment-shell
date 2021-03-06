echo "Test: Read settings from config.ini..."
source <(grep = config.ini | tr -d "\r")

echo "Test: Installing Azure CLI IoT Extension..."
az extension add --name azure-iot

echo "Test: Logging in..."
az login --service-principal -u $AzUsername -p $AzPassword -t $AzTenant

echo "Test: Set the active subscription..."
az account set --subscription $AzSubscription

echo "Test: Start the VM..."
az vm start -g $AzResourceGroup -n $AzVmName

echo "Test: Wait for VM to install automated updates..."
sleep 60

echo "Test: Set up the iotedge-config.json file..."
sed -i s/{azureContainerRegistryName}/$AcrName/g iotedge-config.json
sed -i s/{azureContainerRegistryAddress}/$AcrAddress/g iotedge-config.json
sed -i s/{azureContainerRegistryUsername}/$AcrUsername/g iotedge-config.json
sed -i s~{azureContainerRegistryPassword}~$AcrPassword~g iotedge-config.json
sed -i s~{azureContainerRegistryImageUri}~$AcrImageUri~g iotedge-config.json

echo "Test: Install ssh-client..."
apt install openssh-client
echo "Test: Install sshpass..."
apt install sshpass

echo "Test: Generate key for passwordless login to device..."
echo "" | ssh-keygen -t rsa -b 4096 -C productreadiness -P ""
echo "Test: Disable Strict Host Key Checking..."
ssh -o "StrictHostKeyChecking=no" $UserName@$IpAddress
echo "Test: Copy ssh key to device..."
echo "$Password" | sshpass ssh-copy-id -f $UserName@$IpAddress

# Bash: Exit on error
set -e

echo "Test: Running remote deployment script..."
./remote.sh

# Bash: No exit on error
set +e

echo "Test: Running reset script..."
./reset.sh

echo "Test: Deallocate the VM..."
az vm deallocate -g $AzResourceGroup -n $AzVmName

echo "Test: Complete!"
