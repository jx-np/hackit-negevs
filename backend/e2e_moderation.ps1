# Moderation flow test. Requires moderator@demo.sg elevated to moderator in the DB.
$ErrorActionPreference = "Stop"
$base = "http://localhost:8080/api/v1"
$pass = 0; $fail = 0
function Check($name, $cond, $detail="") { if ($cond) { Write-Host "  PASS  $name" -ForegroundColor Green; $script:pass++ } else { Write-Host "  FAIL  $name -> $detail" -ForegroundColor Red; $script:fail++ } }

$mod = Invoke-RestMethod "$base/auth/login" -Method POST -ContentType application/json -Body (@{email="moderator@demo.sg";password="password123"}|ConvertTo-Json)
$mh = @{ Authorization = "Bearer $($mod.access_token)" }
Check "moderator login (role=$($mod.user.role))" ($mod.user.role -eq "moderator")

$queue = Invoke-RestMethod "$base/moderation/queue" -Headers $mh
Check "GET /moderation/queue has items" ($queue.items.Count -ge 1) "count=$($queue.items.Count)"

# Review the first post flag
$item = $queue.items | Where-Object { $_.target_type -eq "post" } | Select-Object -First 1
if ($item) {
    $dec = Invoke-RestMethod "$base/moderation/posts/$($item.target_id)/review" -Method POST -Headers $mh -ContentType application/json -Body (@{decision="reviewed";rationale="Checked, redaction adequate"}|ConvertTo-Json)
    Check "review post -> reviewed" ($dec.decision -eq "reviewed" -and $dec.post_id -ne $null) "dec=$($dec.decision)"
    # Queue should now have one fewer item
    $q2 = Invoke-RestMethod "$base/moderation/queue" -Headers $mh
    Check "queue shrank after review" ($q2.items.Count -lt $queue.items.Count)
} else { Write-Host "  (no post flag in queue)" -ForegroundColor Yellow }

Write-Host "`nPASSED: $pass   FAILED: $fail" -ForegroundColor $(if($fail -eq 0){"Green"}else{"Red"})
