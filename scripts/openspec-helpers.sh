#!/bin/bash
# OpenSpec Helpers
# 
# Utility commands for working with OpenSpec specs in the workspace.

set -euo pipefail

WORKSPACE="$HOME/.openclaw/workspace"
SPECS_DIR="$WORKSPACE/specs"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

usage() {
  cat << EOF
OpenSpec Helpers

Usage: $(basename "$0") <command> [options]

Commands:
  validate          Validate all specs (TypeScript compilation)
  list              List all specs
  add <name>        Create a new spec from template
  docs              Generate documentation (TODO: configure OpenSpec CLI)
  help              Show this help

Examples:
  $(basename "$0") validate
  $(basename "$0") list
  $(basename "$0") add spotify-control
EOF
}

validate_specs() {
  echo -e "${BLUE}🔍 Validating OpenSpec specs...${NC}"
  cd "$WORKSPACE"
  
  if npx tsc --noEmit specs/*.ts 2>&1; then
    echo -e "${GREEN}✅ All specs are valid${NC}"
    return 0
  else
    echo -e "${RED}❌ Validation failed${NC}"
    return 1
  fi
}

list_specs() {
  echo -e "${BLUE}📋 Available specs:${NC}\n"
  
  for spec in "$SPECS_DIR"/*.spec.ts; do
    [ -f "$spec" ] || continue
    
    name=$(basename "$spec" .spec.ts)
    description=$(grep -A1 "^ \*" "$spec" | grep -v "^ \* $name" | head -1 | sed 's/^ \* //' || echo "No description")
    
    echo -e "${GREEN}$name${NC}"
    echo "  $description"
    echo
  done
}

add_spec() {
  local name="$1"
  local spec_file="$SPECS_DIR/$name.spec.ts"
  
  if [ -f "$spec_file" ]; then
    echo -e "${RED}❌ Spec already exists: $spec_file${NC}"
    return 1
  fi
  
  echo -e "${BLUE}📝 Creating new spec: $name${NC}"
  
  cat > "$spec_file" << EOF
/**
 * ${name^} Spec
 * 
 * TODO: Add description
 */

export interface ${name^}Input {
  /** TODO: Add input params */
  param1: string;
}

export interface ${name^}Output {
  /** TODO: Add output fields */
  result: string;
  timestamp: string;
}

/**
 * Execute ${name}
 */
export async function execute${name^}(
  input: ${name^}Input
): Promise<${name^}Output> {
  throw new Error('Implementation via: scripts/${name}.sh');
}
EOF
  
  # Add to index
  echo "export * from './$name.spec';" >> "$SPECS_DIR/index.ts"
  
  echo -e "${GREEN}✅ Created: $spec_file${NC}"
  echo -e "${YELLOW}📝 Don't forget to:${NC}"
  echo "  1. Fill in the interfaces"
  echo "  2. Update the implementation note"
  echo "  3. Run: $(basename "$0") validate"
}

generate_docs() {
  echo -e "${YELLOW}⚠️  OpenSpec doc generation not yet configured${NC}"
  echo "TODO: Configure openspec CLI and generate docs"
  echo "For now, the specs themselves serve as documentation"
}

# Main
case "${1:-help}" in
  validate)
    validate_specs
    ;;
  list)
    list_specs
    ;;
  add)
    if [ -z "${2:-}" ]; then
      echo -e "${RED}❌ Missing spec name${NC}"
      echo "Usage: $(basename "$0") add <name>"
      exit 1
    fi
    add_spec "$2"
    ;;
  docs)
    generate_docs
    ;;
  help|--help|-h)
    usage
    ;;
  *)
    echo -e "${RED}❌ Unknown command: $1${NC}\n"
    usage
    exit 1
    ;;
esac
