# Desired State Configuration Scripts

This respository contains Desired State Configuration Scripts which specific Resource Templates will refer to a Desired State Configuration Script to perform an automated configuration, management and maintenance of Windows-based servers.

## Desired State Configuration Script in a Template

You specify a Desired State Configuration Script in the **Resources** Section of a Virtual Machine Template. See [vm-dsc.template.json](https://github.com/mrptsai/resources/blob/master/vm-dsc.template.json) as an example.

An **extensions** Resource is configured in the Template using parameters passed from the Project Template and/or Infrastucture Template. 

For example:

```JSON
        {
            "name": "[parameters('vm-settings').name]",
            "type": "Microsoft.Compute/virtualMachines",
            "location": "[resourceGroup().location]",
            "apiVersion": "2015-06-15",
            "dependsOn": [
                "[resourceId('Microsoft.Network/networkInterfaces', parameters('nic-settings').name)]"
            ],
            "tags": {
                "displayName": "[parameters('vm-settings').name]"
            },
            "properties": {
                "hardwareProfile": {
                    "vmSize": "[parameters('vm-settings').vmSize]"
                },
                "osProfile": {
                    "computerName": "[parameters('vm-settings').name]",
                    "adminUsername": "[parameters('vm-settings').adminUsername]",
                    "adminPassword": "[parameters('vm-settings').adminPassword]",
                    "windowsConfiguration": {
                        "provisionVMAgent": true,
                        "enableAutomaticUpdates": true
                    }
                },
                "storageProfile": {
                    "imageReference": {
                        "publisher": "[parameters('vm-settings').imagePublisher]",
                        "offer": "[parameters('vm-settings').imageOffer]",
                        "sku": "[parameters('vm-settings').imageSku]",
                        "version": "latest"
                    },
                    "osDisk": {
                        "name": "[variables('osDiskName')]",
                        "vhd": {
                            "uri": "[concat('https://', variables('storageName'), '.blob.core.windows.net/', parameters('vm-settings').storageAccountContainerName, '/', variables('osDiskName'), '.vhd')]"
                        },
                        "caching": "ReadWrite",
                        "createOption": "FromImage"
                    },
                    "dataDisks": [
                        {
                            "name": "[variables('dataDiskName')]",
                            "lun": 0,
                            "diskSizeGB": "50",
                            "vhd": {
                                "uri": "[concat('https://', variables('storageName'), '.blob.core.windows.net/', parameters('vm-settings').storageAccountContainerName, '/', variables('dataDiskName'), '.vhd')]"
                            },
                            "caching": "ReadOnly",
                            "createOption": "Empty"
                        }
                    ]
                },
                "networkProfile": {
                    "networkInterfaces": [
                        {
                            "id": "[resourceId('Microsoft.Network/networkInterfaces', parameters('nic-settings').name)]"
                        }
                    ]
                }
            },            
            "resources": [        
                {
                    "name": "[parameters('dsc-settings').name]",
                    "type": "extensions",
                    "location": "[resourceGroup().location]",
                    "apiVersion": "2015-06-15",
                    "dependsOn": [
                        "[resourceId('Microsoft.Compute/virtualMachines', parameters('vm-settings').name)]"
                    ],
                    "tags": {
                        "displayName": "[parameters('dsc-settings').name]"
                    },
                    "properties": {
                        "publisher": "Microsoft.Powershell",
                        "type": "DSC",
                        "typeHandlerVersion": "2.9",
                        "autoUpgradeMinorVersion": true,
                        "forceUpdateTag": "v.1.0",
                        "settings": {
                            "configuration": {
                                "url": "[variables('dscScriptsUrl')]",
                                "script": "[concat(parameters('dsc-settings').name, '.ps1')]",
                                "function": "Main"
                            },
                            "configurationArguments": {
                                "nodeName": "[parameters('vm-settings').name]"
                            }
                        },
                        "protectedSettings": null
                    }
                }
            ]
        }
```

## Prerequisites

- Access to Azure
- Parameters from Project and/or Infrastucture Templates must be present. See examples above.

## Versioning

We use [Github](http://github.com/) for version control.

## Authors

* **Paul Towler** - *Initial work* - [resources](https://github.com/mrptsai/resources)

See also the list of [contributors](https://github.com/mrptsai/resources/graphs/contributors) who participated in this project.
