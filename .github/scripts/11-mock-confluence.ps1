param(
    [string]$Version,
    [string]$RcNumber,
    [string]$SpecialVersion   = "",
    [string]$IsRealRelease    = "false",
    [string]$RunId,
    [string]$Repository,
    [string]$Actor,
    [string]$CommitSha,
    [string]$BranchName,
    [string]$InstallerPath    = "",
    [string]$InstallerFiles   = "",
    [string]$InstallerAvgSize = "",
    [string]$SigningStatus     = "",
    [string]$QaFreshInstall   = "",
    [string]$QaUpgrade        = "",
    [string]$QaUninstall      = "",
    [string]$QaSilentInstall  = "",
    [string]$QaDefaultPath    = "",
    [string]$QaAppLaunch      = "",
    [string]$QaSmokeTest      = "",
    [string]$QaNoErrors       = "",
    [string]$QaLogsReviewed   = "",
    [string]$QaApprovedBy     = "",
    [string]$QaApprovedDate   = "",
    [string]$ReleaseDate,
    [string]$ServerUrl        = "https://github.com"
)

# ── Pre-compute display values ──────────────────────────────────────────────
$releaseName = "SDS2 $Version RC$RcNumber"
if ($SpecialVersion) { $releaseName += " ($SpecialVersion)" }

$releaseTypeStr = if ($IsRealRelease -eq "true") { "Major / Minor" } else { "RC / Pre-release" }
$runUrl         = "$ServerUrl/$Repository/actions/runs/$RunId"
$repoUrl        = "$ServerUrl/$Repository"

# Installer fields
$installerFilesRows = ""
if ($InstallerFiles) {
    $InstallerFiles -split ",\s*" | ForEach-Object {
        $name = $_.Trim()
        if ($name) { $installerFilesRows += "<tr><td colspan='2'>$name</td></tr>`n  " }
    }
}

# Signing
function SignCell($status) {
    switch ($status) {
        "passed"    { return '<span class="lbl lbl-green">&#x2705; Yes - Signed</span>' }
        "failed"    { return '<span class="lbl lbl-red">&#x274C; No - Signing Failed</span>' }
        "not-found" { return '<span class="lbl lbl-red">&#x274C; Signing tool not found</span>' }
        default     { return '<span class="lbl lbl-yellow">TBD</span>' }
    }
}
$signingCell     = SignCell $SigningStatus
$sigVerifiedCell = if ($SigningStatus -eq "passed") { '<span class="lbl lbl-green">&#x2705; Yes</span>' } else { '<span class="lbl lbl-yellow">TBD</span>' }

# QA cell helper
function QaCell($val) {
    if (-not $val) { return '<span class="lbl lbl-yellow">TBD</span>' }
    if ($val -eq "Passed" -or $val -eq "Yes") { return '<span class="lbl lbl-green">&#x2705; ' + $val + '</span>' }
    if ($val -eq "Failed" -or $val -eq "No")  { return '<span class="lbl lbl-red">&#x274C; ' + $val + '</span>' }
    return $val
}

$qaApprovedByCell   = if ($QaApprovedBy)   { $QaApprovedBy }   else { '<span class="lbl lbl-yellow">TBD</span>' }
$qaApprovedDateCell = if ($QaApprovedDate) { $QaApprovedDate } else { '<span class="lbl lbl-yellow">TBD</span>' }
$installerPathCell  = if ($InstallerPath)    { $InstallerPath }    else { '<span class="lbl lbl-yellow">TBD</span>' }
$installerSizeCell  = if ($InstallerAvgSize) { "$InstallerAvgSize (avg)" } else { '<span class="lbl lbl-yellow">TBD</span>' }

# ── Generate HTML ───────────────────────────────────────────────────────────
$html = @"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>$releaseName - QA Handoff - Confluence</title>
  <style>
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    body   { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Arial, sans-serif;
             font-size: 14px; color: #172B4D; background: #F4F5F7; }

    /* ── Confluence top nav bar ── */
    .cf-topbar {
      background: #0052CC; height: 56px; display: flex; align-items: center;
      padding: 0 16px; position: sticky; top: 0; z-index: 100;
      box-shadow: 0 2px 4px rgba(0,0,0,.3);
    }
    .cf-topbar-logo { display: flex; align-items: center; gap: 8px; text-decoration: none; }
    .cf-topbar-logo svg { width: 28px; height: 28px; }
    .cf-topbar-logo span { color: #fff; font-size: 18px; font-weight: 700; letter-spacing: -.3px; }
    .cf-topbar-nav { display: flex; gap: 4px; margin-left: 16px; }
    .cf-topbar-nav a {
      color: rgba(255,255,255,.85); text-decoration: none; padding: 6px 10px;
      border-radius: 3px; font-size: 13px;
    }
    .cf-topbar-nav a:hover { background: rgba(255,255,255,.15); color: #fff; }
    .cf-topbar-search {
      margin-left: auto; background: rgba(255,255,255,.15); border: 1px solid rgba(255,255,255,.3);
      border-radius: 3px; padding: 6px 12px; color: rgba(255,255,255,.7);
      font-size: 13px; width: 220px; cursor: not-allowed;
    }
    .cf-topbar-avatar {
      width: 32px; height: 32px; border-radius: 50%;
      background: #FF5630; color: #fff; display: flex; align-items: center;
      justify-content: center; font-weight: 700; font-size: 13px;
      margin-left: 12px; flex-shrink: 0;
    }

    /* ── Layout ── */
    .cf-layout { display: flex; min-height: calc(100vh - 56px); }

    /* ── Sidebar ── */
    .cf-sidebar {
      width: 240px; flex-shrink: 0; background: #fff;
      border-right: 1px solid #DFE1E6; padding: 16px 0;
      position: sticky; top: 56px; height: calc(100vh - 56px); overflow-y: auto;
    }
    .cf-sidebar-space {
      padding: 8px 16px 12px; font-size: 11px; font-weight: 700;
      text-transform: uppercase; color: #5E6C84; letter-spacing: .08em;
    }
    .cf-sidebar-item {
      padding: 7px 16px; font-size: 13px; color: #172B4D;
      cursor: pointer; display: flex; align-items: center; gap: 8px;
    }
    .cf-sidebar-item:hover { background: #F4F5F7; }
    .cf-sidebar-item.active { background: #DEEBFF; color: #0052CC; font-weight: 600;
      border-right: 3px solid #0052CC; }
    .cf-sidebar-icon { width: 16px; height: 16px; flex-shrink: 0; }

    /* ── Main content ── */
    .cf-main { flex: 1; padding: 32px 40px 60px; max-width: 960px; }

    /* ── Breadcrumb ── */
    .cf-breadcrumb { font-size: 12px; color: #5E6C84; margin-bottom: 20px; display: flex; gap: 4px; }
    .cf-breadcrumb a { color: #5E6C84; text-decoration: none; }
    .cf-breadcrumb a:hover { color: #0052CC; text-decoration: underline; }
    .cf-breadcrumb .sep { color: #C1C7D0; }

    /* ── Page title ── */
    .cf-page-title { font-size: 28px; font-weight: 700; color: #172B4D; margin-bottom: 6px; line-height: 1.2; }
    .cf-page-meta   { display: flex; align-items: center; gap: 16px; font-size: 12px;
                      color: #5E6C84; margin-bottom: 24px; padding-bottom: 16px;
                      border-bottom: 1px solid #DFE1E6; }
    .cf-page-meta-avatar {
      width: 24px; height: 24px; border-radius: 50%; background: #FF5630;
      color: #fff; display: flex; align-items: center; justify-content: center;
      font-weight: 700; font-size: 10px; flex-shrink: 0;
    }

    /* ── Info panel (mock) ── */
    .cf-info-panel {
      background: #FFFAE6; border: 1px solid #F6C342; border-radius: 3px;
      padding: 12px 16px; margin-bottom: 24px; font-size: 13px;
      display: flex; gap: 10px; align-items: flex-start;
    }
    .cf-info-icon { font-size: 16px; flex-shrink: 0; margin-top: 1px; }

    /* ── Section headings ── */
    .cf-section { margin-top: 32px; margin-bottom: 12px; }
    .cf-section h2 {
      font-size: 16px; font-weight: 700; color: #172B4D;
      padding-bottom: 6px; border-bottom: 2px solid #DFE1E6;
    }

    /* ── Tables ── */
    table { border-collapse: collapse; width: 100%; margin-bottom: 4px; font-size: 13px; }
    th {
      background: #F4F5F7; text-align: left; padding: 8px 12px;
      border: 1px solid #DFE1E6; font-weight: 600; color: #5E6C84;
      font-size: 11px; text-transform: uppercase; letter-spacing: .05em;
    }
    td { padding: 10px 12px; border: 1px solid #DFE1E6; vertical-align: top; }
    tr:nth-child(even) td { background: #FAFBFC; }

    /* ── Status labels ── */
    .lbl {
      display: inline-flex; align-items: center; gap: 4px;
      padding: 2px 8px; border-radius: 3px; font-size: 12px; font-weight: 600;
    }
    .lbl-green  { background: #E3FCEF; color: #006644; }
    .lbl-red    { background: #FFEBE6; color: #BF2600; }
    .lbl-yellow { background: #FFFAE6; color: #974F0C; font-style: italic; font-weight: 400; }

    /* ── Inline list of files ── */
    .file-list { list-style: none; padding: 0; }
    .file-list li { padding: 3px 0; font-family: monospace; font-size: 12px; color: #172B4D; }
    .file-list li::before { content: "📦 "; }

    /* ── Page footer ── */
    .cf-footer { margin-top: 40px; padding-top: 16px; border-top: 1px solid #DFE1E6;
                 font-size: 11px; color: #97A0AF; }
    a { color: #0052CC; text-decoration: none; }
    a:hover { text-decoration: underline; }
  </style>
</head>
<body>

<!-- Top navigation bar -->
<nav class="cf-topbar">
  <a class="cf-topbar-logo" href="#">
    <svg viewBox="0 0 32 32" fill="none" xmlns="http://www.w3.org/2000/svg">
      <path d="M1.2 24.1c-.4.6-.1 1.4.6 1.6l8.2 2.6c.6.2 1.3-.1 1.6-.7l4-8.6-8.9-3.5L1.2 24.1z" fill="#fff" opacity=".7"/>
      <path d="M30.8 7.9c.4-.6.1-1.4-.6-1.6L22 3.7c-.6-.2-1.3.1-1.6.7l-4 8.6 8.9 3.5 5.5-8.6z" fill="#fff"/>
    </svg>
    <span>Confluence</span>
  </a>
  <nav class="cf-topbar-nav">
    <a href="#">Spaces</a>
    <a href="#">People</a>
    <a href="#">Templates</a>
  </nav>
  <div class="cf-topbar-search">Search...</div>
  <div class="cf-topbar-avatar">$($Actor.Substring(0,[Math]::Min(2,$Actor.Length)).ToUpper())</div>
</nav>

<!-- Layout -->
<div class="cf-layout">

  <!-- Sidebar -->
  <aside class="cf-sidebar">
    <div class="cf-sidebar-space">SDS2 Releases</div>
    <div class="cf-sidebar-item">
      <svg class="cf-sidebar-icon" viewBox="0 0 24 24" fill="#5E6C84"><path d="M3 13h8V3H3v10zm0 8h8v-6H3v6zm10 0h8V11h-8v10zm0-18v6h8V3h-8z"/></svg>
      Overview
    </div>
    <div class="cf-sidebar-item">
      <svg class="cf-sidebar-icon" viewBox="0 0 24 24" fill="#5E6C84"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/></svg>
      Release Notes
    </div>
    <div class="cf-sidebar-item active">
      <svg class="cf-sidebar-icon" viewBox="0 0 24 24" fill="#0052CC"><path d="M9 11l3 3L22 4"/><path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"/></svg>
      QA Handoff Checklists
    </div>
    <div class="cf-sidebar-item">
      <svg class="cf-sidebar-icon" viewBox="0 0 24 24" fill="#5E6C84"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
      Build History
    </div>
  </aside>

  <!-- Main content -->
  <main class="cf-main">

    <!-- Breadcrumb -->
    <div class="cf-breadcrumb">
      <a href="#">Spaces</a><span class="sep">/</span>
      <a href="#">SDS2 Releases</a><span class="sep">/</span>
      <a href="#">QA Handoff Checklists</a><span class="sep">/</span>
      <span>$releaseName</span>
    </div>

    <!-- Page title -->
    <div class="cf-page-title">Desktop Application Release Checklist - QA Handoff</div>
    <div class="cf-page-meta">
      <div class="cf-page-meta-avatar">$($Actor.Substring(0,[Math]::Min(2,$Actor.Length)).ToUpper())</div>
      <span>Created by <strong>$Actor</strong></span>
      <span>&middot;</span>
      <span>Last updated <strong>$ReleaseDate</strong></span>
      <span>&middot;</span>
      <a href="$runUrl">View Build Run #$RunId</a>
    </div>

    <!-- Info banner -->
    <div class="cf-info-panel">
      <div class="cf-info-icon">&#x26A0;&#xFE0F;</div>
      <div>
        <strong>MOCK PAGE</strong> &mdash; Auto-generated by GitHub Actions.
        Fields marked <span class="lbl lbl-yellow">TBD</span> must be completed manually before formal QA handoff.
      </div>
    </div>

    <!-- 1. Release Identification -->
    <div class="cf-section"><h2>1. Release Identification</h2></div>
    <table>
      <tr><th>#</th><th>Field</th><th>Value</th></tr>
      <tr><td>1</td><td>Application Name</td><td>SDS2</td></tr>
      <tr><td>2</td><td>Application Type</td><td>Desktop Application</td></tr>
      <tr><td>3</td><td>Release Name</td><td><strong>$releaseName</strong></td></tr>
      <tr><td>4</td><td>Version Number</td><td>$Version</td></tr>
      <tr><td>5</td><td>Build Number / CI Job ID</td><td><a href="$runUrl">$RunId</a></td></tr>
      <tr><td>6</td><td>Release Type</td><td>$releaseTypeStr</td></tr>
      <tr><td>7</td><td>Release Date</td><td>$ReleaseDate</td></tr>
    </table>

    <!-- 2. Source & Build Information -->
    <div class="cf-section"><h2>2. Source &amp; Build Information</h2></div>
    <table>
      <tr><th>#</th><th>Field</th><th>Value</th></tr>
      <tr><td>1</td><td>Source Repository</td><td><a href="$repoUrl">$Repository</a></td></tr>
      <tr><td>2</td><td>Branch / Tag</td><td><code>$BranchName</code></td></tr>
      <tr><td>3</td><td>Commit ID</td><td><code>$CommitSha</code></td></tr>
      <tr><td>4</td><td>Build Tool / Pipeline</td><td>GitHub Actions</td></tr>
      <tr><td>5</td><td>Build Triggered By</td><td>$Actor</td></tr>
      <tr><td>6</td><td>Build Status</td><td><span class="lbl lbl-green">&#x2705; Success</span></td></tr>
    </table>

    <!-- 3. Installer Details -->
    <div class="cf-section"><h2>3. Installer Details</h2></div>
    <table>
      <tr><th>#</th><th>Field</th><th>Value</th></tr>
      <tr><td>1</td><td>Installer Type</td><td>EXE (NSIS)</td></tr>
      <tr><td>2</td><td>Installer File Name(s)</td><td>
        <ul class="file-list">
          $($InstallerFiles -split ",\s*" | Where-Object { $_.Trim() } | ForEach-Object { "<li>$($_.Trim())</li>" } | Out-String)
        </ul>
      </td></tr>
      <tr><td>3</td><td>Installer Version</td><td>$Version</td></tr>
      <tr><td>4</td><td>Installer Size (avg)</td><td>$installerSizeCell</td></tr>
      <tr><td>5</td><td>Target OS</td><td>Windows</td></tr>
    </table>

    <!-- 4. Installer Signing & Security -->
    <div class="cf-section"><h2>4. Installer Signing &amp; Security Validation</h2></div>
    <table>
      <tr><th>#</th><th>Check</th><th>Status</th></tr>
      <tr><td>1</td><td>Installer Digitally Signed</td><td>$signingCell</td></tr>
      <tr><td>2</td><td>Installer Signature Verified</td><td>$sigVerifiedCell</td></tr>
    </table>

    <!-- 5. Artifact Location -->
    <div class="cf-section"><h2>5. Artifact Location (QA Pickup Point)</h2></div>
    <table>
      <tr><th>#</th><th>Field</th><th>Value</th></tr>
      <tr><td>1</td><td>Common Path / Network Location</td><td><code>$installerPathCell</code></td></tr>
      <tr><td>2</td><td>Previous Release Retained</td><td><span class="lbl lbl-yellow">Yes</span></td></tr>
    </table>

    <!-- 6. Installation & Upgrade Validation -->
    <div class="cf-section"><h2>6. Installation &amp; Upgrade Validation</h2></div>
    <table>
      <tr><th>#</th><th>Check</th><th>QA Result</th></tr>
      <tr><td>1</td><td>Fresh Install Tested</td><td>$(QaCell $QaFreshInstall)</td></tr>
      <tr><td>2</td><td>Upgrade from Previous Version Tested</td><td>$(QaCell $QaUpgrade)</td></tr>
      <tr><td>3</td><td>Uninstall Tested</td><td>$(QaCell $QaUninstall)</td></tr>
      <tr><td>4</td><td>Default Install Path Verified</td><td>$(QaCell $QaDefaultPath)</td></tr>
    </table>

    <!-- 7. Pre-QA Validation -->
    <div class="cf-section"><h2>7. Pre-QA Validation &amp; QA Sign-off Results</h2></div>
    <table>
      <tr><th>#</th><th>Validation</th><th>Status</th></tr>
      <tr><td>1</td><td>Application Launch Verified</td><td>$(QaCell $QaAppLaunch)</td></tr>
      <tr><td>2</td><td>No Critical Install Errors Observed</td><td>$(QaCell $QaNoErrors)</td></tr>
      <tr><td>3</td><td>Installer Logs Reviewed</td><td>$(QaCell $QaLogsReviewed)</td></tr>
    </table>

    <!-- 8. Known Issues -->
    <div class="cf-section"><h2>8. Known Issues &amp; Limitations</h2></div>
    <p style="color:#5E6C84;font-style:italic;padding:8px 0">None recorded at time of handoff. QA to document findings during testing.</p>

    <!-- 9. QA Handoff Confirmation -->
    <div class="cf-section"><h2>9. QA Handoff Confirmation</h2></div>
    <table>
      <tr><th>#</th><th>Role</th><th>Name</th><th>Date</th><th>Signature</th></tr>
      <tr><td>1</td><td>Release Owner</td><td>$Actor</td><td>$ReleaseDate</td><td><span class="lbl lbl-yellow">TBD</span></td></tr>
      <tr><td>2</td><td>QA Lead</td><td>$qaApprovedByCell</td><td>$qaApprovedDateCell</td><td><span class="lbl lbl-green">&#x2705; Approved via GitHub Actions</span></td></tr>
    </table>

    <!-- 10. References -->
    <div class="cf-section"><h2>10. References &amp; Attachments</h2></div>
    <ul style="padding-left:20px;line-height:2">
      <li>Build Run: <a href="$runUrl">GitHub Actions Run #$RunId</a></li>
      <li>Release Notes: <span class="lbl lbl-yellow">TBD</span></li>
      <li>Related Work Items: <span class="lbl lbl-yellow">TBD</span></li>
    </ul>

    <div class="cf-footer">
      Auto-generated by GitHub Actions &middot; $ReleaseDate &middot;
      <a href="$runUrl">Run #$RunId</a>
    </div>

  </main>
</div>

</body>
</html>
"@

# ── Write output ────────────────────────────────────────────────────────────
$null    = New-Item -ItemType Directory -Path "qa-handoff-report" -Force
$outFile = "qa-handoff-report\SDS2-$Version-RC$RcNumber-QA-Handoff.html"
$html | Out-File -FilePath $outFile -Encoding UTF8
Write-Host ">>> Mock Confluence checklist written to: $outFile"
