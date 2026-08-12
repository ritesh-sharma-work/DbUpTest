# PowerShell Script to Enforce Additive-Only Database Migrations
# Scans SQL scripts in the scripts/ folder for prohibited destructive statements.

param (
    [string]$ScriptsFolder = "./scripts"
)

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " Additive-Only Migration Policy Validator" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Scanning folder: $ScriptsFolder"

if (-not (Test-Path -Path $ScriptsFolder)) {
    Write-Host "Error: Scripts folder '$ScriptsFolder' not found!" -ForegroundColor Red
    exit 1
}

# Restricted regex patterns representing destructive operations
$restrictedPatterns = @(
    @{ Pattern = '\bDROP\s+TABLE\b'; Description = 'DROP TABLE is prohibited by additive-only policy.' },
    @{ Pattern = '\bDROP\s+COLUMN\b'; Description = 'DROP COLUMN is prohibited by additive-only policy.' },
    @{ Pattern = '\bDROP\s+PROCEDURE\b'; Description = 'DROP PROCEDURE is prohibited by additive-only policy.' },
    @{ Pattern = '\bDROP\s+PROC\b'; Description = 'DROP PROC is prohibited by additive-only policy.' },
    @{ Pattern = '\bDROP\s+VIEW\b'; Description = 'DROP VIEW is prohibited by additive-only policy.' },
    @{ Pattern = '\bDROP\s+INDEX\b'; Description = 'DROP INDEX is prohibited by additive-only policy.' },
    @{ Pattern = '\bALTER\s+TABLE\b.*\bDROP\b'; Description = 'Destructive ALTER TABLE ... DROP is prohibited.' },
    @{ Pattern = '\bTRUNCATE\s+TABLE\b'; Description = 'TRUNCATE TABLE is prohibited.' }
)

# Find all active SQL migration files (excluding .sample files)
$sqlFiles = Get-ChildItem -Path $ScriptsFolder -Recurse -Filter "*.sql" | Where-Object { $_.Name -notlike "*.sample" }

if ($sqlFiles.Count -eq 0) {
    Write-Host "No SQL migration files found to validate." -ForegroundColor Yellow
    exit 0
}

$hasErrors = $false

foreach ($file in $sqlFiles) {
    Write-Host "Checking: $($file.FullName)"
    $lines = Get-Content -Path $file.FullName
    $lineNumber = 0

    foreach ($line in $lines) {
        $lineNumber++
        # Ignore comments
        $trimmedLine = $line.Trim()
        if ($trimmedLine.StartsWith("--") -or $trimmedLine.StartsWith("/*")) {
            continue
        }

        foreach ($rule in $restrictedPatterns) {
            if ($line -match $rule.Pattern) {
                Write-Host "  [FAIL] Line $lineNumber : $($rule.Description)" -ForegroundColor Red
                Write-Host "         Content: $trimmedLine" -ForegroundColor DarkRed
                $hasErrors = $true
            }
        }
    }
}

Write-Host "------------------------------------------"
if ($hasErrors) {
    Write-Host "POLICY VALIDATION FAILED!" -ForegroundColor Red
    Write-Host "One or more SQL migration scripts contain prohibited destructive operations." -ForegroundColor Red
    Write-Host "Please update your migrations to comply with the Additive-Only strategy." -ForegroundColor Red
    exit 1
} else {
    Write-Host "POLICY VALIDATION PASSED!" -ForegroundColor Green
    Write-Host "All SQL migration scripts adhere to the Additive-Only strategy." -ForegroundColor Green
    exit 0
}
