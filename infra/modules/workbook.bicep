@description('The name of the workbook')
param workbookName string

@description('The location for the workbook')
param location string = resourceGroup().location

@description('The Log Analytics workspace resource ID')
param logAnalyticsWorkspaceId string

@description('Tags to apply to the workbook')
param tags object = {}

var workbookSourceId = logAnalyticsWorkspaceId

resource workbook 'Microsoft.Insights/workbooks@2023-06-01' = {
  name: guid(workbookName, resourceGroup().id)
  location: location
  tags: tags
  kind: 'shared'
  properties: {
    displayName: workbookName
    serializedData: loadTextContent('../workbook-template.json')
    version: '1.0'
    sourceId: workbookSourceId
    category: 'workbook'
  }
}

output workbookId string = workbook.id
output workbookName string = workbook.name
