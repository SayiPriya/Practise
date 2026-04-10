# Serves C:\qa-reports\ at http://localhost:8080
# Run this once on your machine: & .github\scripts\start-qa-server.ps1
# Leave the window open. New reports appear automatically after each workflow run.

$root = "C:\qa-reports"
$port = 8080

$null = New-Item -ItemType Directory -Path $root -Force
$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add("http://localhost:$port/")
$listener.Start()

Write-Host ""
Write-Host "=== QA Report Server running ==="
Write-Host "    URL  : http://localhost:$port/"
Write-Host "    Folder: $root"
Write-Host "    Press Ctrl+C to stop."
Write-Host ""

try {
    while ($listener.IsListening) {
        $ctx  = $listener.GetContext()
        $req  = $ctx.Request
        $resp = $ctx.Response

        $rawPath = $req.Url.LocalPath.TrimStart('/')

        # index: list all HTML files
        if ($rawPath -eq "" -or $rawPath -eq "index.html") {
            $files   = Get-ChildItem -Path $root -Filter "*.html" | Sort-Object LastWriteTime -Descending
            $links   = $files | ForEach-Object {
                "  <li><a href='/$($_.Name)'>$($_.Name)</a> &mdash; $($_.LastWriteTime.ToString('yyyy-MM-dd HH:mm'))</li>"
            }
            $body    = @"
<!DOCTYPE html><html><head><meta charset='UTF-8'>
<title>QA Reports</title>
<style>body{font-family:Arial,sans-serif;margin:40px;color:#172B4D}
h1{color:#0052CC}li{margin:6px 0}a{color:#0052CC}</style></head>
<body><h1>QA Handoff Reports</h1>
<ul>$($links -join "`n")</ul>
<p style='color:#6B778C;font-size:12px'>Auto-updated on each workflow run &mdash; just refresh.</p>
</body></html>
"@
            $bytes = [System.Text.Encoding]::UTF8.GetBytes($body)
            $resp.ContentType     = "text/html; charset=utf-8"
            $resp.ContentLength64 = $bytes.Length
            $resp.OutputStream.Write($bytes, 0, $bytes.Length)
        }
        else {
            $file = Join-Path $root $rawPath
            if (Test-Path $file -PathType Leaf) {
                $bytes = [System.IO.File]::ReadAllBytes($file)
                $resp.ContentType     = "text/html; charset=utf-8"
                $resp.ContentLength64 = $bytes.Length
                $resp.OutputStream.Write($bytes, 0, $bytes.Length)
            }
            else {
                $resp.StatusCode = 404
                $msg  = [System.Text.Encoding]::UTF8.GetBytes("404 Not Found: $rawPath")
                $resp.OutputStream.Write($msg, 0, $msg.Length)
            }
        }

        $resp.OutputStream.Close()
    }
}
finally {
    $listener.Stop()
    Write-Host "Server stopped."
}
