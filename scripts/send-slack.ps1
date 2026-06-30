# Gong Pipeline Slack Digest
# Reads SLACK_WEBHOOK_URL from ../.env and flagged_deals.json from ../output/
# Usage: powershell -ExecutionPolicy Bypass -File send-slack.ps1

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectDir = Split-Path -Parent $scriptDir

# Load .env
$envFile = Join-Path $projectDir ".env"
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^\s*([^#][^=]*)\s*=\s*(.*)\s*$') {
            [System.Environment]::SetEnvironmentVariable($matches[1].Trim(), $matches[2].Trim())
        }
    }
}

$webhookUrl = [System.Environment]::GetEnvironmentVariable("SLACK_WEBHOOK_URL")
if (-not $webhookUrl) {
    Write-Host "SLACK_WEBHOOK_URL not set in .env — skipping Slack digest." -ForegroundColor Yellow
    exit 0
}

# Load flagged deals
$jsonPath = Join-Path $projectDir "output\flagged_deals.json"
if (-not (Test-Path $jsonPath)) {
    Write-Host "flagged_deals.json not found — run pipeline hygiene first." -ForegroundColor Red
    exit 1
}

$data = Get-Content $jsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
$summary = $data.summary
$deals = $data.flagged_deals
$date = $data.generated_date

$critical = $deals | Where-Object { $_.health_category -eq "Critical" }
$warning  = $deals | Where-Object { $_.health_category -eq "Warning" }
$watch    = $deals | Where-Object { $_.health_category -eq "Watch" }

$arrAtRisk = "$" + [math]::Round($summary.arr_at_risk / 1000000, 2) + "M"

# Build Block Kit payload
$blocks = @()

# Header
$blocks += @{
    type = "header"
    text = @{ type = "plain_text"; text = "Gong Pipeline Digest — $date"; emoji = $false }
}

# Summary stats
$statText = "*$($summary.total_deals)* deals total  |  *$($summary.flagged_count)* flagged  |  *$arrAtRisk* at risk  |  Avg score: *$($summary.avg_health_score)*"
$blocks += @{
    type = "section"
    text = @{ type = "mrkdwn"; text = $statText }
}

$blocks += @{ type = "divider" }

# Critical deals — one block each
if ($critical.Count -gt 0) {
    $blocks += @{
        type = "section"
        text = @{ type = "mrkdwn"; text = ":red_circle: *CRITICAL ($($critical.Count) deals)*" }
    }

    foreach ($d in $critical) {
        $daysText = if ($d.days_since_activity -eq 1) { "1 day" } else { "$($d.days_since_activity) days" }
        $arrK = "$" + [math]::Round($d.arr / 1000) + "K"
        $flagText = if ($d.flags -and $d.flags.Count -gt 0) { $d.flags[0] } else { "No recent activity" }
        $text = "*$($d.deal_name)*  |  $($d.ae_name)  |  $arrK  |  $daysText dark`n>$flagText"
        $blocks += @{
            type = "section"
            text = @{ type = "mrkdwn"; text = $text }
        }
    }

    $blocks += @{ type = "divider" }
}

# Warning rollup
if ($warning.Count -gt 0) {
    $names = ($warning | ForEach-Object { $_.deal_name }) -join ", "
    $blocks += @{
        type = "section"
        text = @{ type = "mrkdwn"; text = ":large_orange_circle: *WARNING ($($warning.Count) deals)*`n$names" }
    }
}

# Watch rollup
if ($watch.Count -gt 0) {
    $names = ($watch | ForEach-Object { $_.deal_name }) -join ", "
    $blocks += @{
        type = "section"
        text = @{ type = "mrkdwn"; text = ":large_yellow_circle: *WATCH ($($watch.Count) deals)*`n$names" }
    }
}

$blocks += @{ type = "divider" }

# Dashboard link
$blocks += @{
    type = "section"
    text = @{ type = "mrkdwn"; text = "<https://gong-pipeline.vercel.app|View full dashboard :arrow_upper_right:>" }
}

$payload = @{ blocks = $blocks } | ConvertTo-Json -Depth 10 -Compress

try {
    $response = Invoke-RestMethod -Uri $webhookUrl -Method Post -Body $payload -ContentType "application/json"
    Write-Host "Slack digest sent successfully." -ForegroundColor Green
} catch {
    Write-Host "Failed to send Slack digest: $_" -ForegroundColor Red
    exit 1
}
