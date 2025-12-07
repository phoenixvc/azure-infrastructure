// ============================================================================
// Azure Naming Module v2.1
// ============================================================================

@description('Owning organisation code')
@allowed(['nl', 'pvc', 'tws', 'mys'])
param org string

@description('Deployment environment')
@allowed(['dev', 'staging', 'prod'])
param env string

@description('Logical project / system name')
@minLength(2)
@maxLength(20)
param project string

@description('Short region code')
@allowed(['euw', 'eun', 'wus', 'eus', 'san', 'saf', 'swe', 'uks', 'usw', 'glob'])
param region string

var base = '${org}-${env}-${project}'

output rgName string = '${base}-rg-${region}'
output name_app string = '${base}-app-${region}'
output name_api string = '${base}-api-${region}'
output name_func string = '${base}-func-${region}'
output name_swa string = '${base}-swa-${region}'
output name_db string = '${base}-db-${region}'
output name_storage string = '${org}${env}${replace(project, '-', '')}storage${region}'
output name_kv string = '${base}-kv-${region}'
output name_queue string = '${base}-queue-${region}'
output name_cache string = '${base}-cache-${region}'
output name_ai string = '${base}-ai-${region}'
output name_acr string = '${org}${env}${replace(project, '-', '')}acr${region}'
output name_vnet string = '${base}-vnet-${region}'
output name_subnet string = '${base}-subnet-${region}'
output name_dns string = '${base}-dns-${region}'
output name_log string = '${base}-log-${region}'

output baseName string = base
output pattern string = '[org]-[env]-[project]-[type]-[region]'
output version string = 'v2.1'
