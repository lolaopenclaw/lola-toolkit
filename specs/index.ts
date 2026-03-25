/**
 * OpenSpec Specifications Index
 * 
 * This directory contains TypeScript specs for workspace components.
 * Specs define contracts (inputs/outputs) for scripts, skills, and tools.
 * 
 * Usage:
 * - Write spec-first when building new tools
 * - Generate docs: npx openspec generate
 * - Validate against real implementations
 * 
 * Conventions:
 * - One spec per tool/script/skill
 * - Use JSDoc comments for descriptions
 * - Export input/output interfaces + functions
 * - Throw Error with implementation note (since we're documenting existing tools)
 */

export * from './garmin-health-report.spec';
export * from './truthcheck.spec';
