# Indus App Store Upload Script
# Generated: 2026-05-01

$API_KEY = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzUxMiJ9.eyJpc3MiOiJpZGVudGl0eU1hbmFnZXIiLCJ2ZXJzaW9uIjoiNC4wIiwidGlkIjoiOTY3Yjc3NDItZDI5Ny00YTg1LWIzMGMtMmM3M2U4MzhkNDdjIiwic2lkIjoiOWI4MjQyNTktNTYzZS00YTNlLTg0MDctZjcwNGNmNTMxMGJiIiwiaWF0IjoxNzczODQ1MDkwLCJleHAiOjIwODkyMDUwOTB9.CFCPsovZYCPUd68cDygNxWne1tnmaNw0D2yhj6vrIp4oNpKuKAsLWVDykDSUJF43fGyFIcryHO4HvOjj8ZGTjg"
$BASE_URL = "https://developer-api.indusappstore.com"

$apps = @(
    @{ Name = "JMukhisics"; Package = "in.jmukhisics.mobile_app"; APK = "build/app/outputs/flutter-apk/app-jmukhisics-release.apk"; Version = "1.0.4"; VersionCode = 5 },
    @{ Name = "SIC School"; Package = "in.sicschool.mobile_app"; APK = "build/app/outputs/flutter-apk/app-sicschool-release.apk"; Version = "1.0.4"; VersionCode = 5 },
    @{ Name = "SchoolFeePro"; Package = "in.schoolfeepro.mobile_app"; APK = "build/app/outputs/flutter-apk/app-schoolfeepro-release.apk"; Version = "1.0.4"; VersionCode = 5 },
    @{ Name = "The Shivalik"; Package = "in.theshivalik.mobile_app"; APK = "build/app/outputs/flutter-apk/app-theshivalik-release.apk"; Version = "1.0.3"; VersionCode = 4 }
)

$results = @()
$timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"

foreach ($app in $apps) {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Uploading $($app.Name) v$($app.Version)" -ForegroundColor Cyan
    Write-Host "Package: $($app.Package)" -ForegroundColor Gray
    Write-Host "APK: $($app.APK)" -ForegroundColor Gray
    Write-Host "========================================" -ForegroundColor Cyan

    $url = "$BASE_URL/devtools/apk/upgrade/$($app.Package)"
    $headers = @{
        "Authorization" = "Bearer $API_KEY"
    }

    try {
        $response = curl.exe -X POST $url `
            -H "Authorization: Bearer $API_KEY" `
            -F "file=@$($app.APK)" `
            -w "`nHTTP_CODE:%{http_code}" `
            -s `
            --max-time 300

        $httpCode = ($response -match "HTTP_CODE:(\d+)" | ForEach-Object { $matches[1] })
        $body = $response -replace "HTTP_CODE:\d+", "" -replace "^\s*", "" -replace "\s*$", ""

        Write-Host "HTTP Status: $httpCode" -ForegroundColor Yellow
        Write-Host "Response: $body" -ForegroundColor Gray

        $results += @{
            Name = $app.Name
            Package = $app.Package
            Version = $app.Version
            VersionCode = $app.VersionCode
            StatusCode = $httpCode
            Response = $body
            Success = ($httpCode -eq "200")
            Timestamp = $timestamp
        }
    }
    catch {
        Write-Host "ERROR uploading $($app.Name): $_" -ForegroundColor Red
        $results += @{
            Name = $app.Name
            Package = $app.Package
            Version = $app.Version
            VersionCode = $app.VersionCode
            StatusCode = "ERR"
            Response = $_.Exception.Message
            Success = $false
            Timestamp = $timestamp
        }
    }
}

# Generate report
Write-Host "`n`n========================================" -ForegroundColor Green
Write-Host "UPLOAD SUMMARY" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

foreach ($r in $results) {
    $status = if ($r.Success) { "✅ SUCCESS" } else { "❌ FAILED" }
    $color = if ($r.Success) { "Green" } else { "Red" }
    Write-Host "$status - $($r.Name) (HTTP $($r.StatusCode))" -ForegroundColor $color
}

# Export JSON for report generation
$results | ConvertTo-Json -Depth 5 | Set-Content -Path "scripts/upload_results.json" -Encoding UTF8
Write-Host "`nResults saved to scripts/upload_results.json" -ForegroundColor Gray
