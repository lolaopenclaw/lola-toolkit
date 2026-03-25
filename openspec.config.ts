import { defineConfig } from 'openspec';

export default defineConfig({
  // Entry point for specs
  entry: './specs/index.ts',
  
  // Output directory for generated docs
  output: './docs/openspec',
  
  // Project info
  info: {
    title: 'Lola OpenClaw Workspace',
    version: '1.0.0',
    description: 'TypeScript specifications for workspace scripts, skills, and tools',
  },
  
  // Generate OpenAPI spec
  openapi: {
    enabled: true,
    version: '3.1.0',
  },
  
  // Generate TypeScript client (disabled for now, since we already have implementations)
  client: {
    enabled: false,
  },
  
  // Generate TypeScript server (disabled for now)
  server: {
    enabled: false,
  },
});
