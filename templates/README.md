# Pattern Templates

This respository contains Infrastructure Templates where each one will build a different set of infrastructure depending on the Parameters passed from a Project Template. 

## Linking to an Infrastructure Template

You create a link between the two templates by adding a Deployment Resource within the Project Template that points to a linked Infrastructure Template. You set the templateLink property to the URI of the linked Infrastructure Template. You can provide parameter values for the linked Infrastructure Template either by specifying the values directly in the Project Template or by linking to a parameter file. 

First, in the Project Templates, we capture any user defined parameters:

```JSON
	"parameters": {
		"baseUrl": {
		    "type": "string",
		    "metadata": {
			"description": "Select the appropriate Repository Base URL containing Pattern Templates and Resource Templates"
		    },
		    "defaultValue": "https://raw.githubusercontent.com/mrptsai/",
		    "allowedValues": [
			"https://raw.githubusercontent.com/mrptsai/"
		    ]
		},
		"patternName": {
		    "type": "string",
		    "metadata": {
			"description": "Select the appropriate Architectural Pattern"
		    },
		    "defaultValue": "vm-dsc-poc-1",
		    "allowedValues": [
			"vm-poc-1",
			"vm-dsc-poc-1",
			"vm-3tier-poc-1"
		    ]
		},
		"storageAccountName": {
		    "type": "string",
		    "metadata": {
			"description": "Enter a unique Name for a new Storage Account or specify the name of an existing Storage Account. Use PowerShell and the following command to generate a unique Storage Account Name 'storage + (-join ((48..57) + (97..122) | Get-Random -Count 15 | % {[char]$_}))'"
		    }
		},
	},    
```

Next, the **Variables** section in a Project Template can then have complex variables defined that will be used to pass these Variables as Parameters to the Infrastructure Templates

For example:

```JSON
	"variables": {
		"templatesFolder": "templates/master",
		"templateUrl": "[concat(parameters('baseUrl'), variables('templatesFolder'), '/', parameters('patternName'), '.json')]",
		"storage-settings": {
		    "name": "[parameters('storageAccountName')]",
		    "newOrExisting": "[parameters('storageNewOrExisting')]",
		    "existingRg": "[parameters('storageExistingResourceGroup')]"
		},
		"vnet-settings": {
		    "name": "[parameters('virtualNetworkName')]",
		    "newOrExisting": "[parameters('virtualNetworkNewOrExisting')]",
		    "existingRg": "[parameters('virtualNetworkExistingResourceGroup')]",
		    "prefix": "[parameters('virtualNetworkPrefix')]",
		    "subnets": {
			"subnet0Prefix": "[parameters('subnet0Prefix')]",
			"subnet0Name": "[parameters('subnet0Name')]"
		    }
		},
		"vm-settings": {
		    "adminUserName": "[parameters('vmAdminUserName')]",
		    "adminPassword": "[parameters('vmAdminPassword')]"
		}
    	},  
```

Finally, the **Resources** section in a Project Template, a Deployment Resource is added that points to a linked Infrastructure Template along with Parameters that are passed to the linked Infrastructure Template.

For example:

```JSON
	"resources": [
        {
            "name": "[parameters('patternName')]",
            "type": "Microsoft.Resources/deployments",
            "apiVersion": "2015-01-01",
            "dependsOn": [],
            "properties": {
                "mode": "Incremental",
                "templateLink": {
                    "uri": "[variables('templateUrl')]",
                    "contentVersion": "1.0.0.0"
                },
                "parameters": {
                    "storage-settings": {
                        "value": "[variables('storage-settings')]"
                    },
                    "vnet-settings": {
                        "value": "[variables('vnet-settings')]"
                    },
                    "vm-settings": {
                        "value": "[variables('vm-settings')]"
                    },
                    "baseUrl": {
                        "value": "[parameters('baseUrl')]"
                    }
                }
            }
        }
    ],
```

## Parameters

Every Infrastructure Pattern Template requires different parameters, but the Infrastucture Templates expect parameters passed to it, are already captured in the Project Template. Parameters are received by the Infrastucture Template by defining Parameters as specified below. 

For example:

```JSON
	"parameters": {
		"storage-settings": {
		    "type": "object",
		    "metadata": {
			"description": "These are settings for the Storage Account"
		    }
		},
		"vnet-settings": {
		    "type": "object",
		    "metadata": {
			"description": "These are settings for the Virtual Network"
		    }
		},
		"vm-settings": {
		    "type": "object",
		    "metadata": {
			"description": "These are settings for the Virtual Machine"
		    }
		},
		"baseUrl": {
		    "type": "string",
		    "metadata": {
			"description": "Base URL for Resource and Shared Templates"
		    }
		}
	},
```

**NOTE:**
The Parameters configured in the Project Template MUST match the Paramters to be received by the Infrastructure Template.**

## Prerequisites

- Access to Azure
- Infrastructure Templates must be called by a Project Template. See examples above.

## Versioning

We use [Github](http://github.com/) for version control.

## Authors

* **Paul Towler** - *Initial work* - [templates](https://github.com/mrptsai/templates)

See also the list of [contributors](https://github.com/mrptsai/templates/graphs/contributors) who participated in this project.
