targetScope = 'resourceGroup'

@description('Azure region for all resources.')
param location string

@description('Resource tags.')
param tags object

@description('Virtual network name.')
param vnetName string

@description('Virtual machine subnet name.')
param subnetName string

@description('Network security group name.')
param nsgName string

@description('Public IP address name.')
param publicIpName string

@description('Network interface name.')
param nicName string

@description('Virtual machine resource name.')
param vmName string

@description('Windows computer name. Windows limits this value to 15 characters.')
@maxLength(15)
param computerName string

@description('Operating system disk name.')
param osDiskName string

@description('Managed data disk name.')
param dataDiskName string

@description('Local administrator username.')
@minLength(1)
@maxLength(20)
param adminUsername string

@description('Local administrator password. Supply this securely at deployment time.')
@secure()
@minLength(12)
param adminPassword string

@description('Virtual machine size.')
param vmSize string

@description('Virtual network CIDR address space.')
@minLength(9)
param vnetAddressSpace string

@description('Virtual machine subnet CIDR address space.')
@minLength(9)
param subnetAddressSpace string

@description('Source allowed to connect through RDP.')
param rdpSourceAddressPrefix string

@description('RDP destination port.')
@minValue(1)
@maxValue(65535)
param rdpPort int

@description('Priority assigned to the RDP security rule.')
@minValue(100)
@maxValue(4096)
param rdpRulePriority int

@description('Marketplace image publisher.')
param imagePublisher string

@description('Marketplace image offer.')
param imageOffer string

@description('Marketplace image SKU.')
param imageSku string

@description('Marketplace image version.')
param imageVersion string

@description('Storage SKU used by the operating system disk.')
@allowed([
  'Premium_LRS'
  'StandardSSD_LRS'
  'Standard_LRS'
])
param osDiskStorageType string

@description('Storage SKU used by the data disk.')
@allowed([
  'Premium_LRS'
  'StandardSSD_LRS'
  'Standard_LRS'
])
param dataDiskStorageType string

@description('Managed data disk capacity in GiB.')
@minValue(1)
@maxValue(32767)
param dataDiskSizeGB int

@description('Enables Secure Boot for Trusted Launch.')
param secureBootEnabled bool

@description('Enables the virtual Trusted Platform Module.')
param vTpmEnabled bool

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: nsgName
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'Allow-RDP-From-Internet'
        properties: {
          description: 'Allows inbound RDP access from the configured source.'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: string(rdpPort)
          sourceAddressPrefix: rdpSourceAddressPrefix
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: rdpRulePriority
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressSpace
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetAddressSpace
          networkSecurityGroup: {
            id: networkSecurityGroup.id
          }
        }
      }
    ]
  }
}

resource publicIpAddress 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: publicIpName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

resource networkInterface 'Microsoft.Network/networkInterfaces@2024-05-01' = {
  name: nicName
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
          }
          publicIPAddress: {
            id: publicIpAddress.id
          }
        }
      }
    ]
  }
  dependsOn: [
    virtualNetwork
  ]
}

resource dataDisk 'Microsoft.Compute/disks@2024-03-02' = {
  name: dataDiskName
  location: location
  tags: tags
  sku: {
    name: dataDiskStorageType
  }
  properties: {
    diskSizeGB: dataDiskSizeGB
    creationData: {
      createOption: 'Empty'
    }
  }
}

resource virtualMachine 'Microsoft.Compute/virtualMachines@2024-07-01' = {
  name: vmName
  location: location
  tags: tags
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: imageSku
        version: imageVersion
      }
      osDisk: {
        name: osDiskName
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: osDiskStorageType
        }
      }
      dataDisks: [
        {
          lun: 0
          name: dataDisk.name
          createOption: 'Attach'
          diskSizeGB: dataDiskSizeGB
          managedDisk: {
            id: dataDisk.id
            storageAccountType: dataDiskStorageType
          }
        }
      ]
    }
    osProfile: {
      computerName: computerName
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: true
        patchSettings: {
          patchMode: 'AutomaticByOS'
          assessmentMode: 'ImageDefault'
        }
      }
    }
    securityProfile: {
      securityType: 'TrustedLaunch'
      uefiSettings: {
        secureBootEnabled: secureBootEnabled
        vTpmEnabled: vTpmEnabled
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
          properties: {
            primary: true
          }
        }
      ]
    }
  }
}

output resourceGroupName string = resourceGroup().name
output virtualMachineId string = virtualMachine.id
output virtualMachineName string = virtualMachine.name
output publicIpAddress string = publicIpAddress.properties.ipAddress
output networkInterfaceId string = networkInterface.id
output dataDiskId string = dataDisk.id
