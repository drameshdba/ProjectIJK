# Resource Templates

This respository contains Resource Templates where each template builds a specific Resource. These templates require parameters passed from the Infrastructure Templates. 

## Linking to a Resource Template

You create a link between the two templates by adding a Deployment Resource within the Infrastucture Template that points to a linked Resource Template. You set the templateLink property to the URI of the linked Resource Template. You can provide parameter values for the linked Resource Template either by specifying the values directly in the Infrastucture Template or by linking to a parameter file. 

In the Infrastucture Templates, the **Resources** section, a Deployment Resource is specified and points to a linked Resource Template along with complex Parameters that are passed to the Resource Template.

For example:

```JSON
	"resources": [
        {
            "name": "shared-resources",
            "type": "Microsoft.Resources/deployments",
            "apiVersion": "2016-09-01",
            "dependsOn": [],
            "properties": {
                "mode": "Incremental",
                "templateLink": {
                    "uri": "[variables('sharedTemplate')]",
                    "contentVersion": "1.0.0.0"
                },
                "parameters": {
                    "storage-settings": {
                        "value": {
                            "name": "[parameters('storage-settings').name]",
                            "accountType": "Standard_LRS",
                            "newOrExisting": "[parameters('storage-settings').newOrExisting]",
                            "existingRg": "[parameters('storage-settings').existingRg]"
                        }
                    },
                    "vnet-settings": {
                        "value": {
                            "name": "[parameters('vnet-settings').name]",
                            "newOrExisting": "[parameters('vnet-settings').newOrExisting]",
                            "existingRg": "[parameters('vnet-settings').existingRg]",
                            "prefix": "[parameters('vnet-settings').prefix]",
                            "subnets": [
                                {
                                    "name": "[parameters('vnet-settings').subnets.subnet0Name]",
                                    "properties": {
                                        "addressPrefix": "[parameters('vnet-settings').subnets.subnet0Prefix]"
                                    }
                                }
                            ],
                            "dnsSettings": []
                        }
                    },
                    "resourcesUrl": {
                        "value": "[variables('resourcesUrl')]"
                    }
                }
            }
        },
        {
            "name": "virtual-machine",
            "type": "Microsoft.Resources/deployments",
            "apiVersion": "2015-01-01",
            "dependsOn": [
                "[resourceId('Microsoft.Resources/deployments', 'shared-resources')]"
            ],
            "properties": {
                "mode": "Incremental",
                "templateLink": {
                    "uri": "[variables('vmTemplate')]",
                    "contentVersion": "1.0.0.0"
                },
                "parameters": {
                    "storage-settings": {
                        "value": "[parameters('storage-settings')]"
                    },
                    "nic-settings": {
                        "value": {
                            "name": "vm-nic",
                            "privateIPAllocationMethod": "Dynamic",
                            "subnetRef": "[concat(reference('shared-resources').outputs.vnetID.value, '/subnets/', parameters('vnet-settings').subnets.subnet0Name)]"
                        }
                    },
                    "vm-settings": {
                        "value": {
                            "name": "vm-1",
                            "adminUserName": "[parameters('vm-settings').adminUserName]",
                            "adminPassword": "[parameters('vm-settings').adminPassword]",
                            "imagePublisher": "MicrosoftWindowsServer",
                            "imageOffer": "WindowsServer",
                            "imageSku": "2016-Datacenter",
                            "vmSize": "Standard_D2_v2",
                            "storageAccountContainerName": "[toLower(resourceGroup().name)]"
                        }
                    }
                }
            }
        }
    ],
```
## Parameters

Every Resource Template requires different parameters, but the Resource Templates expect parameters passed to it, are already captured in the Project Template, then passed to the Infrastructure Template. Parameters are received by the Resource Template by defining Parameters as specified below. 

For example:

```JSON
	"parameters": {
        "storage-settings": {
            "type": "object",
            "metadata": {
                "description": "These are settings for the Storage"
            }
        },
        "nic-settings": {
            "type": "object",
            "metadata": {
                "description": "These are settings for a Network Interface"
            }
        },
        "vm-settings": {
            "type": "object",
            "metadata": {
                "description": "These are settings for a VM"
            }
        }

    },
```

**NOTE:**
The Parameters configured in the Infrastructure Template MUST match the Paramters to be received by the Resources Template.**

## Prerequisites

- Access to Azure
- Resource Templates must be called by an Infrastucture Template. See examples above.

## Versioning

We use [Github](http://github.com/) for version control.

## Authors

* **Paul Towler** - *Initial work* - [resources](https://github.com/mrptsai/resources)

See also the list of [contributors](https://github.com/mrptsai/resources/graphs/contributors) who participated in this project.
