// Test file for naming module
targetScope = 'subscription'

module naming 'main.bicep' = {
name: 'naming-test'
params: {
  org: 'nl'
  env: 'dev'
  project: 'test'
  region: 'euw'
}
}

output testResults object = {
rgName: naming.outputs.rgName
apiName: naming.outputs.name_api
funcName: naming.outputs.name_func
storageName: naming.outputs.name_storage
kvName: naming.outputs.name_kv
}
