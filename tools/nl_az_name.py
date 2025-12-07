#!/usr/bin/env python3
"""Azure Naming Convention Validator v2.1"""

import re
import sys
import argparse
from pathlib import Path
from typing import Tuple, Optional

VALID_ORGS = ['nl', 'pvc', 'tws', 'mys']
VALID_ENVS = ['dev', 'staging', 'prod']
VALID_TYPES = ['app', 'api', 'func', 'swa', 'db', 'storage', 'kv', 'queue', 'cache', 'ai', 'acr', 'vnet', 'subnet', 'dns', 'log', 'rg']
VALID_REGIONS = ['euw', 'eun', 'wus', 'eus', 'san', 'saf', 'swe', 'uks', 'usw', 'glob']

RESOURCE_PATTERN = r'^([a-z]+)-([a-z]+)-([a-z0-9\-]+)-([a-z]+)-([a-z]+)$'
RG_PATTERN = r'^([a-z]+)-([a-z]+)-([a-z0-9\-]+)-rg-([a-z]+)$'

def validate_resource_name(name: str) -> Tuple[bool, str, Optional[dict]]:
  """Validate a resource name against the standard pattern."""
  if not re.match(r'^[a-z0-9\-]+$', name):
      return False, "Invalid characters (only a-z, 0-9, - allowed)", None
  
  if name.startswith('-') or name.endswith('-'):
      return False, "Cannot start or end with hyphen", None
  
  # Try resource group pattern
  rg_match = re.match(RG_PATTERN, name)
  if rg_match:
      org, env, project, region = rg_match.groups()
      if org not in VALID_ORGS:
          return False, f"Invalid org '{org}'", None
      if env not in VALID_ENVS:
          return False, f"Invalid env '{env}'", None
      if region not in VALID_REGIONS:
          return False, f"Invalid region '{region}'", None
      return True, f"✅ Valid: {name}", {'org': org, 'env': env, 'project': project, 'type': 'rg', 'region': region}
  
  # Try standard resource pattern
  res_match = re.match(RESOURCE_PATTERN, name)
  if res_match:
      org, env, project, type_code, region = res_match.groups()
      if org not in VALID_ORGS:
          return False, f"Invalid org '{org}'", None
      if env not in VALID_ENVS:
          return False, f"Invalid env '{env}'", None
      if type_code not in VALID_TYPES:
          return False, f"Invalid type '{type_code}'", None
      if region not in VALID_REGIONS:
          return False, f"Invalid region '{region}'", None
      return True, f"✅ Valid: {name}", {'org': org, 'env': env, 'project': project, 'type': type_code, 'region': region}
  
  return False, "Does not match pattern [org]-[env]-[project]-[type]-[region]", None

def main():
  parser = argparse.ArgumentParser(description='Azure Naming Validator v2.1')
  subparsers = parser.add_subparsers(dest='command', required=True)
  
  validate_parser = subparsers.add_parser('validate', help='Validate a resource name')
  validate_parser.add_argument('name', help='Resource name to validate')
  
  args = parser.parse_args()
  
  if args.command == 'validate':
      is_valid, message, components = validate_resource_name(args.name)
      print(message)
      if components:
          print("\nComponents:")
          for key, value in components.items():
              print(f"  {key}: {value}")
      sys.exit(0 if is_valid else 1)

if __name__ == '__main__':
  main()
