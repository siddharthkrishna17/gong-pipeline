# Gong Pipeline Slack Digest
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

$jsonPath = Join-Path $projectDir "output\flagged_deals.json"
if (-not (Test-Path $jsonPath)) {
    Write-Host "flagged_deals.json not found — run pipeline hygiene first." -ForegroundColor Red
    exit 1
}

$data    = Get-Content $jsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
$s       = $data.summary
$deals   = $data.flagged_deals
$date    = $data.generated_date

$critical = @($deals | Where-Object { $_.health_category -eq "Critical" })
$warning  = @($deals | Where-Object { $_.health_category -eq "Warning" })
$watch    = @($deals | Where-Object { $_.health_category -eq "Watch" })

function Fmt-ARR($n) { "$" + [math]::Round($n / 1000) + "K" }
function Fmt-ARR-M($n) { "$" + [math]::Round($n / 1000000, 2) + "M" }
function Sum-ARR($list) { ($list | Measure-Object -Property arr -Sum).Sum }

# ── TOP BLOCKS ──────────────────────────────────────────────────────────────
$topBlocks = @(
    @{
        type = "header"
        text = @{ type = "plain_text"; text = "Gong Pipeline Digest  —  $date"; emoji = $false }
    },
    @{
        type   = "section"
        fields = @(
            @{ type = "mrkdwn"; text = "*Total Deals*`n$($s.total_deals)" },
            @{ type = "mrkdwn"; text = "*Flagged*`n$($s.flagged_count)" },
            @{ type = "mrkdwn"; text = "*ARR at Risk*`n$(Fmt-ARR-M $s.arr_at_risk)" },
            @{ type = "mrkdwn"; text = "*Avg Health Score*`n$($s.avg_health_score) / 100" }
        )
    }
)

# ── CRITICAL ATTACHMENT ──────────────────────────────────────────────────────
$critBlocks = @(
    @{
        type = "section"
        text = @{ type = "mrkdwn"; text = "*:red_circle: CRITICAL — $($critical.Count) deals  ·  $(Fmt-ARR (Sum-ARR $critical)) at risk*" }
    },
    @{ type = "divider" }
)

foreach ($d in $critical) {
    $days = if ($d.days_since_activity -eq 1) { "1 day dark" } else { "$($d.days_since_activity) days dark" }
    $flag = if ($d.flags -and $d.flags.Count -gt 0) { $d.flags[0] } else { "" }
    $critBlocks += @{
        type   = "section"
        fields = @(
            @{ type = "mrkdwn"; text = "*$($d.deal_name)*`n$($d.ae_name)  ·  $($d.stage)" },
            @{ type = "mrkdwn"; text = "*$(Fmt-ARR $d.arr)*`n$days" }
        )
    }
    if ($flag) {
        $critBlocks += @{
            type     = "context"
            elements = @(@{ type = "mrkdwn"; text = ":small_red_triangle: $flag" })
        }
    }
}

$critAttachment = @{
    color  = "#EF4444"
    blocks = $critBlocks
}

# ── WARNING ATTACHMENT ───────────────────────────────────────────────────────
$warnLines = $warning | ForEach-Object { "$($_.deal_name) ($(Fmt-ARR $_.arr))" }
$warnBlocks = @(
    @{
        type = "section"
        text = @{ type = "mrkdwn"; text = "*:large_orange_circle: WARNING — $($warning.Count) deals  ·  $(Fmt-ARR (Sum-ARR $warning)) at risk*" }
    },
    @{
        type = "section"
        text = @{ type = "mrkdwn"; text = ($warnLines -join "  ·  ") }
    }
)

$warnAttachment = @{
    color  = "#F97316"
    blocks = $warnBlocks
}

# ── WATCH ATTACHMENT ─────────────────────────────────────────────────────────
$watchLines = $watch | ForEach-Object { "$($_.deal_name) ($(Fmt-ARR $_.arr))" }
$watchBlocks = @(
    @{
        type = "section"
        text = @{ type = "mrkdwn"; text = "*:large_yellow_circle: WATCH — $($watch.Count) deals  ·  $(Fmt-ARR (Sum-ARR $watch)) at risk*" }
    },
    @{
        type = "section"
        text = @{ type = "mrkdwn"; text = ($watchLines -join "  ·  ") }
    }
)

$watchAttachment = @{
    color  = "#EAB308"
    blocks = $watchBlocks
}

# ── FOOTER ATTACHMENT ────────────────────────────────────────────────────────
$footerAttachment = @{
    color  = "#6D28D9"
    blocks = @(
        @{
            type = "section"
            text = @{ type = "mrkdwn"; text = "<https://gong-pipeline.vercel.app|:bar_chart:  Open full dashboard>" }
        }
    )
}

# ── SEND ─────────────────────────────────────────────────────────────────────
$payload = @{
    blocks      = $topBlocks
    attachments = @($critAttachment, $warnAttachment, $watchAttachment, $footerAttachment)
} | ConvertTo-Json -Depth 12 -Compress

try {
    Invoke-RestMethod -Uri $webhookUrl -Method Post -Body $payload -ContentType "application/json" | Out-Null
    Write-Host "Slack digest sent successfully." -ForegroundColor Green
} catch {
    Write-Host "Failed to send Slack digest: $_" -ForegroundColor Red
    exit 1
}
