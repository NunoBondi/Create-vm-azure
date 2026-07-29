# Arquitectura de recursos

El siguiente diagrama muestra las relaciones principales entre los recursos de red, cómputo y almacenamiento:

```mermaid
flowchart TD
    Internet([Internet]) --> PIP[Public IP<br/>pip-vm-wus3-dev-01]
    PIP --> NIC[Network Interface<br/>nic-vm-wus3-dev-01]
    NIC --> VM[Windows VM<br/>vm-w11-wus3-dev-01]
    VM --> Disk[(Managed Data Disk<br/>disk-data-wus3-dev-01)]

    VNet[Virtual Network<br/>vnet-wus3-dev-01] --> Subnet[Subnet<br/>snet-vm-wus3-dev-01]
    Subnet --> NSG[Network Security Group<br/>nsg-vm-wus3-dev-01]
    NSG --> NIC
```

El NSG protege la subnet y permite el acceso RDP configurado. La NIC conecta la máquina virtual con la subnet y con la IP pública, mientras que el disco administrado proporciona almacenamiento de datos adicional.
