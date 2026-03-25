#!/usr/bin/env python3
"""
Subagent Output Validator
Pipeline de validación en 3 fases para outputs de subagentes.

Fase 1: Structural Validation (determinístico)
Fase 2: Semantic Validation (AI reviewer con Haiku)
Fase 3: Human Threshold (decisión final)

Author: Lola (OpenClaw)
Created: 2026-03-24
"""

import re
import json
import sys
import subprocess
import os
from pathlib import Path
from typing import Dict, List, Any, Tuple
from datetime import datetime

# Configuración
WORKSPACE = Path.home() / ".openclaw" / "workspace"
LOGS_DIR = WORKSPACE / "logs" / "subagent-validator"
LOGS_DIR.mkdir(parents=True, exist_ok=True)


class Issue:
    """Representa un issue encontrado en validación"""
    def __init__(self, severity: str, issue_type: str, description: str, line: int = None):
        self.severity = severity  # CRITICAL, HIGH, MEDIUM, LOW
        self.type = issue_type    # secret, destructive, syntax, logic, style
        self.description = description
        self.line = line
    
    def to_dict(self) -> Dict[str, Any]:
        result = {
            'severity': self.severity,
            'type': self.type,
            'description': self.description
        }
        if self.line is not None:
            result['line'] = self.line
        return result


class StructuralValidator:
    """Fase 1: Validación estructural determinística"""
    
    # Patterns para secret scanning
    SECRET_PATTERNS = [
        (r'sk-[a-zA-Z0-9_-]{20,}', 'OpenAI API key'),  # Matches sk-, sk-proj-, etc.
        (r'ghp_[a-zA-Z0-9]{36}', 'GitHub Personal Access Token'),
        (r'xoxb-[a-zA-Z0-9-]+', 'Slack Bot Token'),
        (r'AIza[0-9A-Za-z_-]{35}', 'Google API Key'),
        (r'AKIA[0-9A-Z]{16}', 'AWS Access Key'),
        (r'ya29\.[0-9A-Za-z_-]+', 'Google OAuth Token'),
        (r'sk-ant-[a-zA-Z0-9_-]{20,}', 'Anthropic API key'),  # Added Anthropic
        (r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}', 'Email address'),
        (r'/home/mleon(?:/[^\s]+)?', 'Personal path'),
    ]
    
    # IP privadas
    PRIVATE_IP_PATTERN = r'\b(?:192\.168|10\.|172\.(?:1[6-9]|2[0-9]|3[01])\.)\d{1,3}\.\d{1,3}\b'
    
    # Comandos destructivos
    DESTRUCTIVE_PATTERNS = [
        (r'rm\s+-rf\s+/', 'Recursive delete from root'),
        (r'dd\s+if=/dev/zero', 'Writing zeros to disk'),
        (r'sudo\s+chmod\s+777', 'Making files world-writable'),
        (r'>\s*/dev/sd[a-z]', 'Writing directly to disk'),
        (r'mkfs\s+', 'Formatting filesystem'),
        (r'format\s+[A-Z]:', 'Format command'),
        (r'curl[^|]*\|\s*bash', 'Piping remote script to bash'),
        (r'wget[^|]*\|\s*sh', 'Piping remote script to shell'),
        (r'rm\s+-rf\s+\$HOME', 'Deleting home directory'),
        (r'rm\s+-rf\s+~', 'Deleting home directory'),
    ]
    
    # Modificaciones a directorios críticos
    CRITICAL_DIRS = ['/etc/', '/boot/', '/sys/', '/proc/']
    
    def validate(self, output_text: str) -> Dict[str, Any]:
        """Ejecuta todas las validaciones estructurales"""
        issues = []
        
        # 1. Secret scanning
        issues.extend(self._scan_secrets(output_text))
        
        # 2. Destructive commands
        issues.extend(self._scan_destructive(output_text))
        
        # 3. Syntax validation
        issues.extend(self._validate_syntax(output_text))
        
        # 4. Missing error handling
        issues.extend(self._check_error_handling(output_text))
        
        # 5. Critical directory modifications
        issues.extend(self._check_critical_dirs(output_text))
        
        critical_count = len([i for i in issues if i.severity == 'CRITICAL'])
        
        return {
            'pass': critical_count == 0,
            'issues': [i.to_dict() for i in issues],
            'critical_count': critical_count
        }
    
    def _scan_secrets(self, text: str) -> List[Issue]:
        """Detecta secrets y datos sensibles"""
        issues = []
        lines = text.split('\n')
        
        for line_num, line in enumerate(lines, 1):
            for pattern, description in self.SECRET_PATTERNS:
                if re.search(pattern, line):
                    issues.append(Issue(
                        severity='CRITICAL',
                        issue_type='secret',
                        description=f'{description} detected',
                        line=line_num
                    ))
            
            # IPs privadas
            if re.search(self.PRIVATE_IP_PATTERN, line):
                issues.append(Issue(
                    severity='HIGH',
                    issue_type='secret',
                    description='Private IP address detected',
                    line=line_num
                ))
        
        return issues
    
    def _scan_destructive(self, text: str) -> List[Issue]:
        """Detecta comandos destructivos"""
        issues = []
        lines = text.split('\n')
        
        for line_num, line in enumerate(lines, 1):
            for pattern, description in self.DESTRUCTIVE_PATTERNS:
                if re.search(pattern, line, re.IGNORECASE):
                    issues.append(Issue(
                        severity='CRITICAL',
                        issue_type='destructive',
                        description=f'Destructive command: {description}',
                        line=line_num
                    ))
        
        return issues
    
    def _validate_syntax(self, text: str) -> List[Issue]:
        """Valida sintaxis básica (JSON, Python, Bash)"""
        issues = []
        
        # Detectar tipo de contenido
        if text.strip().startswith('{') or text.strip().startswith('['):
            # Probablemente JSON
            try:
                json.loads(text)
            except json.JSONDecodeError as e:
                issues.append(Issue(
                    severity='CRITICAL',
                    issue_type='syntax',
                    description=f'Invalid JSON: {str(e)}',
                    line=e.lineno if hasattr(e, 'lineno') else None
                ))
        
        elif '#!/bin/bash' in text or '#!/usr/bin/env bash' in text:
            # Bash script - validación básica
            if 'function' in text and not re.search(r'function\s+\w+\s*\(\)', text):
                issues.append(Issue(
                    severity='MEDIUM',
                    issue_type='syntax',
                    description='Bash function syntax may be incorrect'
                ))
        
        elif '#!/usr/bin/env python' in text or 'import ' in text:
            # Python - validación básica con compile
            try:
                compile(text, '<string>', 'exec')
            except SyntaxError as e:
                issues.append(Issue(
                    severity='CRITICAL',
                    issue_type='syntax',
                    description=f'Python syntax error: {str(e)}',
                    line=e.lineno
                ))
        
        return issues
    
    def _check_error_handling(self, text: str) -> List[Issue]:
        """Detecta falta de manejo de errores"""
        issues = []
        
        # Bash sin set -e
        if ('#!/bin/bash' in text or '#!/usr/bin/env bash' in text):
            if 'set -e' not in text and 'set -o errexit' not in text:
                issues.append(Issue(
                    severity='HIGH',
                    issue_type='error_handling',
                    description='Bash script without set -e (errors may be ignored)'
                ))
        
        # Python sin try/except en operaciones de archivo
        if 'import ' in text and ('open(' in text or 'file(' in text):
            if 'try:' not in text and 'except' not in text:
                issues.append(Issue(
                    severity='HIGH',
                    issue_type='error_handling',
                    description='File operations without try/except'
                ))
        
        return issues
    
    def _check_critical_dirs(self, text: str) -> List[Issue]:
        """Detecta modificaciones a directorios críticos"""
        issues = []
        lines = text.split('\n')
        
        for line_num, line in enumerate(lines, 1):
            for critical_dir in self.CRITICAL_DIRS:
                if critical_dir in line and any(cmd in line for cmd in ['rm', 'mv', 'cp', 'chmod', 'chown']):
                    issues.append(Issue(
                        severity='CRITICAL',
                        issue_type='destructive',
                        description=f'Modification to critical directory: {critical_dir}',
                        line=line_num
                    ))
        
        return issues


class SemanticValidator:
    """Fase 2: Validación semántica con AI reviewer (Claude Haiku)"""
    
    REVIEWER_PROMPT_TEMPLATE = """You are a code reviewer for an AI agent system. Review this output from a subagent.

OUTPUT:
{output}

CONTEXT:
- Task: {task}
- Intended action: {action_type}
- Environment: Ubuntu VPS, OpenClaw workspace at /home/mleon/.openclaw/workspace

REVIEW CRITERIA:
1. Does the output correctly fulfill the task?
2. Are there logic bugs or edge cases not handled?
3. Is there any security risk? (secrets, destructive commands, privilege escalation)
4. Does it follow best practices?
5. Could this break existing functionality?

OUTPUT FORMAT (JSON only, no markdown):
{{
  "verdict": "APPROVE" | "REJECT" | "WARN",
  "confidence": 0-100,
  "issues": [
    {{"severity": "CRITICAL|HIGH|MEDIUM|LOW", "type": "security|logic|style", "description": "..."}}
  ],
  "suggested_fixes": ["..."]
}}

Respond with ONLY the JSON object, no other text."""
    
    def validate(self, output_text: str, task: str, action_type: str = "unknown") -> Dict[str, Any]:
        """Ejecuta validación semántica con AI"""
        prompt = self.REVIEWER_PROMPT_TEMPLATE.format(
            output=output_text[:4000],  # Limitar para no exceder contexto
            task=task,
            action_type=action_type
        )
        
        try:
            # Llamar a Claude Haiku via subprocess
            result = subprocess.run(
                ['openclaw', 'chat', '--model', 'haiku', '--print', '--no-stream'],
                input=prompt,
                capture_output=True,
                text=True,
                timeout=30
            )
            
            if result.returncode != 0:
                return self._fallback_response("AI reviewer failed")
            
            # Parsear respuesta
            response = result.stdout.strip()
            
            # Extraer JSON del markdown si es necesario
            if '```json' in response:
                response = response.split('```json')[1].split('```')[0].strip()
            elif '```' in response:
                response = response.split('```')[1].split('```')[0].strip()
            
            verdict_data = json.loads(response)
            
            # Convertir issues a objetos Issue
            issues = []
            for issue_data in verdict_data.get('issues', []):
                issues.append(Issue(
                    severity=issue_data['severity'],
                    issue_type=issue_data['type'],
                    description=issue_data['description']
                ))
            
            return {
                'verdict': verdict_data['verdict'],
                'confidence': verdict_data.get('confidence', 0),
                'issues': [i.to_dict() for i in issues],
                'suggested_fixes': verdict_data.get('suggested_fixes', [])
            }
        
        except subprocess.TimeoutExpired:
            return self._fallback_response("AI reviewer timeout")
        except json.JSONDecodeError:
            return self._fallback_response("AI reviewer returned invalid JSON")
        except Exception as e:
            return self._fallback_response(f"AI reviewer error: {str(e)}")
    
    def _fallback_response(self, reason: str) -> Dict[str, Any]:
        """Respuesta de fallback si AI reviewer falla"""
        return {
            'verdict': 'WARN',
            'confidence': 0,
            'issues': [Issue(
                severity='MEDIUM',
                issue_type='validation',
                description=f'Could not perform semantic validation: {reason}'
            ).to_dict()],
            'suggested_fixes': []
        }


class HumanThresholdDecider:
    """Fase 3: Decisión basada en umbrales"""
    
    def decide(self, structural_result: Dict, semantic_result: Dict) -> Dict[str, Any]:
        """Decide si bloquear, alertar, o permitir"""
        all_issues = structural_result['issues'] + semantic_result['issues']
        
        critical = [i for i in all_issues if i['severity'] == 'CRITICAL']
        high = [i for i in all_issues if i['severity'] == 'HIGH']
        medium = [i for i in all_issues if i['severity'] == 'MEDIUM']
        low = [i for i in all_issues if i['severity'] == 'LOW']
        
        # Decisión
        if len(critical) > 0:
            return {
                'action': 'BLOCK',
                'reason': f'{len(critical)} critical issue(s) detected',
                'all_issues': all_issues,
                'counts': {'critical': len(critical), 'high': len(high), 'medium': len(medium), 'low': len(low)}
            }
        elif len(high) >= 3:
            return {
                'action': 'BLOCK',
                'reason': f'{len(high)} high-severity issues detected (threshold: 3)',
                'all_issues': all_issues,
                'counts': {'critical': len(critical), 'high': len(high), 'medium': len(medium), 'low': len(low)}
            }
        elif len(medium) >= 5:
            return {
                'action': 'WARN',
                'reason': f'{len(medium)} medium-severity issues detected',
                'all_issues': all_issues,
                'counts': {'critical': len(critical), 'high': len(high), 'medium': len(medium), 'low': len(low)}
            }
        else:
            return {
                'action': 'ALLOW',
                'reason': 'No critical issues detected',
                'all_issues': all_issues,
                'counts': {'critical': len(critical), 'high': len(high), 'medium': len(medium), 'low': len(low)}
            }


class SubagentValidator:
    """Pipeline completo de validación"""
    
    def __init__(self):
        self.structural = StructuralValidator()
        self.semantic = SemanticValidator()
        self.decider = HumanThresholdDecider()
    
    def validate(self, output_text: str, task: str, action_type: str = "unknown", 
                 skip_semantic: bool = False) -> Dict[str, Any]:
        """
        Ejecuta pipeline completo de validación.
        
        Args:
            output_text: Output del subagente a validar
            task: Descripción de la tarea original
            action_type: Tipo de acción (config_edit, file_creation, script_execution, etc.)
            skip_semantic: Si True, salta Fase 2 (útil para outputs de solo lectura)
        
        Returns:
            Dict con decisión final y detalles
        """
        start_time = datetime.now()
        
        # Fase 1: Structural
        structural_result = self.structural.validate(output_text)
        
        # Fase 2: Semantic (opcional)
        if skip_semantic or structural_result['critical_count'] > 0:
            # Skip si ya hay críticos o si se pidió explícitamente
            semantic_result = {
                'verdict': 'SKIPPED',
                'confidence': 0,
                'issues': [],
                'suggested_fixes': []
            }
        else:
            semantic_result = self.semantic.validate(output_text, task, action_type)
        
        # Fase 3: Human threshold
        decision = self.decider.decide(structural_result, semantic_result)
        
        end_time = datetime.now()
        latency = (end_time - start_time).total_seconds()
        
        # Log resultado
        log_entry = {
            'timestamp': start_time.isoformat(),
            'latency_seconds': latency,
            'task': task,
            'action_type': action_type,
            'structural': structural_result,
            'semantic': semantic_result,
            'decision': decision
        }
        
        self._log_validation(log_entry)
        
        return {
            'decision': decision['action'],
            'reason': decision['reason'],
            'issues': decision['all_issues'],
            'counts': decision['counts'],
            'latency': latency,
            'suggested_fixes': semantic_result.get('suggested_fixes', [])
        }
    
    def _log_validation(self, log_entry: Dict):
        """Guarda log de validación"""
        log_file = LOGS_DIR / f"{datetime.now().strftime('%Y-%m-%d')}.jsonl"
        with open(log_file, 'a') as f:
            f.write(json.dumps(log_entry) + '\n')


def main():
    """CLI wrapper"""
    import argparse
    
    parser = argparse.ArgumentParser(description='Validate subagent output')
    parser.add_argument('--output', required=True, help='Output text to validate (or path to file with @)')
    parser.add_argument('--task', required=True, help='Original task description')
    parser.add_argument('--action-type', default='unknown', help='Action type (config_edit, file_creation, etc.)')
    parser.add_argument('--skip-semantic', action='store_true', help='Skip semantic validation (Fase 2)')
    parser.add_argument('--json', action='store_true', help='Output JSON instead of human-readable')
    
    args = parser.parse_args()
    
    # Leer output
    if args.output == '-':
        # Leer de stdin
        output_text = sys.stdin.read()
    elif args.output.startswith('@'):
        output_path = Path(args.output[1:])
        if not output_path.exists():
            print(f"Error: File not found: {output_path}", file=sys.stderr)
            sys.exit(1)
        output_text = output_path.read_text()
    else:
        output_text = args.output
    
    # Validar
    validator = SubagentValidator()
    result = validator.validate(output_text, args.task, args.action_type, args.skip_semantic)
    
    # Output
    if args.json:
        print(json.dumps(result, indent=2))
    else:
        print(f"Decision: {result['decision']}")
        print(f"Reason: {result['reason']}")
        print(f"Latency: {result['latency']:.2f}s")
        print(f"\nIssue counts: {result['counts']}")
        
        if result['issues']:
            print(f"\nIssues found ({len(result['issues'])}):")
            for issue in result['issues']:
                line_info = f" (line {issue['line']})" if issue.get('line') else ""
                print(f"  [{issue['severity']}] {issue['type']}: {issue['description']}{line_info}")
        
        if result['suggested_fixes']:
            print(f"\nSuggested fixes:")
            for fix in result['suggested_fixes']:
                print(f"  - {fix}")
    
    # Exit code
    if result['decision'] == 'BLOCK':
        sys.exit(1)
    elif result['decision'] == 'WARN':
        sys.exit(2)
    else:
        sys.exit(0)


if __name__ == '__main__':
    main()
