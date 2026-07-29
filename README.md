# Create VM Azure

## Descripción

Esta solución despliega mediante Bicep la infraestructura base necesaria para ejecutar una máquina virtual Windows en Azure. La plantilla se ejecuta sobre un Resource Group existente y permite configurar nombres, red, imagen, tamaño, almacenamiento y seguridad desde `parameters.json`.

## Recursos desplegados

| Recurso | Nombre | Tipo de recurso Azure | Propósito |
| --- | --- | --- | --- |
| Resource Group | `rg-vm-wus3-dev-01` | `Microsoft.Resources/resourceGroups` | Contenedor existente donde se despliega la solución. La plantilla no lo crea. |
| Virtual Network | `vnet-wus3-dev-01` | `Microsoft.Network/virtualNetworks` | Proporciona el espacio de red privado `10.10.0.0/16`. |
| Subnet | `snet-vm-wus3-dev-01` | `Microsoft.Network/virtualNetworks/subnets` | Segmento `10.10.1.0/24` donde se conecta la VM. |
| Network Security Group | `nsg-vm-wus3-dev-01` | `Microsoft.Network/networkSecurityGroups` | Controla el tráfico y permite RDP TCP/3389 desde el origen configurado. |
| Public IP | `pip-vm-wus3-dev-01` | `Microsoft.Network/publicIPAddresses` | Proporciona una dirección IPv4 pública Standard y estática. |
| Network Interface | `nic-vm-wus3-dev-01` | `Microsoft.Network/networkInterfaces` | Conecta la VM con la subnet y la IP pública. |
| Virtual Machine | `vm-w11-wus3-dev-01` | `Microsoft.Compute/virtualMachines` | Ejecuta Windows con el tamaño y la imagen configurados. |
| Managed Data Disk | `disk-data-wus3-dev-01` | `Microsoft.Compute/disks` | Proporciona 128 GiB de almacenamiento de datos administrado. |

## Arquitectura

El tráfico RDP llega desde Internet a una IP pública asociada a la interfaz de red de la VM. La NIC está conectada a una subnet protegida por un NSG dentro de la red virtual. La VM utiliza un disco administrado para el sistema operativo y otro disco administrado para datos.

Consulta el [diagrama detallado de recursos](arquitectura-recursos.md).

## Requisitos previos

- Azure CLI instalado.
- Sesión iniciada en Azure.
- Suscripción de destino seleccionada.
- Permisos `Contributor` o superiores sobre `rg-vm-wus3-dev-01`.
- Resource Group `rg-vm-wus3-dev-01` creado previamente.

## Despliegue

La plantilla tiene alcance `resourceGroup`, por lo que deben utilizarse los comandos `az deployment group`.

### 1. Iniciar sesión

```bash
az login
```

### 2. Seleccionar la suscripción

```bash
az account set --subscription "<subscription-id>"
```

### 3. Validar el despliegue

Reemplaza primero el marcador `REPLACE_WITH_A_SECURE_PASSWORD` o proporciona la contraseña mediante un mecanismo seguro.

```bash
az deployment group what-if \
  --resource-group rg-vm-wus3-dev-01 \
  --template-file main.bicep \
  --parameters @parameters.json
```

### 4. Ejecutar el despliegue

```bash
az deployment group create \
  --name deploy-windows-vm \
  --resource-group rg-vm-wus3-dev-01 \
  --template-file main.bicep \
  --parameters @parameters.json
```

> Los comandos `az deployment sub` no aplican a esta plantilla porque el Resource Group se crea y administra fuera de ella.

## Recursos resultantes

El despliegue crea una VNet con una subnet protegida por un NSG. Una IP pública se asocia a la NIC y la NIC se conecta tanto a la subnet como a la VM Windows. La VM recibe un disco de sistema operativo administrado y el disco de datos `disk-data-wus3-dev-01` como LUN 0.

Bicep calcula las dependencias entre los recursos y los crea en el orden requerido.

## Acceso a la VM

Obtén la IP pública:

```bash
az network public-ip show \
  --resource-group rg-vm-wus3-dev-01 \
  --name pip-vm-wus3-dev-01 \
  --query ipAddress \
  --output tsv
```

En Windows, abre Conexión a Escritorio remoto con:

```powershell
mstsc /v:<public-ip>
```

Utiliza el usuario configurado en `adminUsername` y la contraseña proporcionada durante el despliegue.

## Limpieza

Eliminar el Resource Group destruye todos los recursos contenidos en él:

```bash
az group delete \
  --name rg-vm-wus3-dev-01 \
  --yes
```
