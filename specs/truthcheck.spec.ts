/**
 * TruthCheck Spec
 * 
 * Verify claims, fact-check content, and trace information to sources.
 * Uses the TruthCheck CLI (pip install truthcheck).
 */

export interface TruthCheckInput {
  /** Claim or content to verify */
  claim: string;
  
  /** Check mode */
  mode: 'verify' | 'trust' | 'trace';
  
  /** Optional: URL to check (for trust mode) */
  url?: string;
  
  /** Max sources to return */
  maxSources?: number;
}

export interface SourceInfo {
  /** Source URL */
  url: string;
  
  /** Source title */
  title: string;
  
  /** Trustworthiness score (0-100) */
  trustScore: number;
  
  /** Publication date (if available) */
  publishedAt?: string;
  
  /** Snippet showing the claim */
  snippet: string;
}

export interface TruthCheckResult {
  /** Original claim */
  claim: string;
  
  /** Verification status */
  status: 'verified' | 'disputed' | 'unverified' | 'mixed';
  
  /** Confidence score (0-100) */
  confidence: number;
  
  /** Supporting sources */
  sources: SourceInfo[];
  
  /** Summary of findings */
  summary: string;
  
  /** Warnings or caveats */
  warnings?: string[];
  
  /** Timestamp of check */
  checkedAt: string;
}

export interface TrustCheckResult {
  /** URL checked */
  url: string;
  
  /** Domain reputation */
  domainReputation: 'high' | 'medium' | 'low' | 'unknown';
  
  /** Trust score (0-100) */
  trustScore: number;
  
  /** Known issues (if any) */
  issues?: string[];
  
  /** Recommendations */
  recommendations: string[];
}

export interface TraceResult {
  /** Original claim */
  claim: string;
  
  /** Earliest known source */
  originSource?: SourceInfo;
  
  /** Propagation timeline */
  timeline: Array<{
    date: string;
    source: SourceInfo;
    context: string;
  }>;
  
  /** Total sources found */
  totalSources: number;
}

/**
 * Verify a claim
 */
export async function verifyClaim(claim: string): Promise<TruthCheckResult> {
  throw new Error('Implementation via CLI: truthcheck verify "<claim>"');
}

/**
 * Check URL trustworthiness
 */
export async function checkTrust(url: string): Promise<TrustCheckResult> {
  throw new Error('Implementation via CLI: truthcheck trust "<url>"');
}

/**
 * Trace claim to origin
 */
export async function traceClaim(claim: string): Promise<TraceResult> {
  throw new Error('Implementation via CLI: truthcheck trace "<claim>"');
}
