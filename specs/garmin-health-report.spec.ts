/**
 * Garmin Health Report Spec
 * 
 * Generates daily health metrics report from Garmin device.
 * Outputs to memory/garmin/ with markdown format.
 */

export interface GarminHealthReportInput {
  /** Date to generate report for (YYYY-MM-DD). Defaults to today. */
  date?: string;
  
  /** Output format */
  format?: 'markdown' | 'json';
  
  /** Include historical comparison (last 7 days) */
  includeHistory?: boolean;
}

export interface GarminHealthMetrics {
  /** Steps count */
  steps: number;
  
  /** Heart rate stats (bpm) */
  heartRate: {
    resting: number;
    min: number;
    max: number;
    avg: number;
  };
  
  /** Sleep duration (hours) */
  sleepHours: number;
  
  /** Sleep quality score (0-100) */
  sleepQuality: number;
  
  /** Stress level (0-100) */
  stressLevel: number;
  
  /** Body battery (0-100) */
  bodyBattery: number;
  
  /** Active calories burned */
  activeCalories: number;
  
  /** Total calories burned */
  totalCalories: number;
}

export interface GarminHealthReportOutput {
  /** Generated report date */
  date: string;
  
  /** Metrics for the day */
  metrics: GarminHealthMetrics;
  
  /** Historical comparison (if requested) */
  history?: {
    avgSteps: number;
    avgSleepHours: number;
    avgStressLevel: number;
  };
  
  /** Output file path */
  outputPath: string;
  
  /** Generation timestamp */
  generatedAt: string;
}

/**
 * Generate Garmin health report
 */
export async function generateGarminHealthReport(
  input: GarminHealthReportInput
): Promise<GarminHealthReportOutput> {
  throw new Error('Implementation via bash script: scripts/garmin-health-report.sh');
}
