# End-to-end API smoke test against a running server + seeded DB.
# Run:  pwsh -File .\e2e_test.ps1
$ErrorActionPreference = "Stop"
$base = "http://localhost:8080/api/v1"
$pass = 0; $fail = 0
function Ok($name)   { Write-Host "  PASS  $name" -ForegroundColor Green; $script:pass++ }
function Bad($name,$detail) { Write-Host "  FAIL  $name -> $detail" -ForegroundColor Red; $script:fail++ }
function Check($name, $cond, $detail="") { if ($cond) { Ok $name } else { Bad $name $detail } }

# unique email per run
$suffix = Get-Random
$email  = "alice$suffix@example.com"
$modEmail = "mod$suffix@example.com"

Write-Host "`n== Health ==" -ForegroundColor Cyan
$live  = Invoke-RestMethod "$base/health/live"
Check "health/live" ($live.status -eq "ok")
$ready = Invoke-RestMethod "$base/health/ready"
Check "health/ready (db)" ($ready.status -eq "ready")

Write-Host "`n== Auth ==" -ForegroundColor Cyan
$reg = Invoke-RestMethod "$base/auth/register" -Method POST -ContentType application/json -Body (@{email=$email;password="password123";display_name="Alice"}|ConvertTo-Json)
Check "register" ($reg.user.id -and $reg.access_token -and $reg.refresh_token)
$access = $reg.access_token; $refresh = $reg.refresh_token
$h = @{ Authorization = "Bearer $access" }

$me = Invoke-RestMethod "$base/me" -Headers $h
Check "GET /me" ($me.email -eq $email -and $me.role -eq "resident")

$login = Invoke-RestMethod "$base/auth/login" -Method POST -ContentType application/json -Body (@{email=$email;password="password123"}|ConvertTo-Json)
Check "login" ($login.access_token -ne $null)

$ref = Invoke-RestMethod "$base/auth/refresh" -Method POST -ContentType application/json -Body (@{refresh_token=$refresh}|ConvertTo-Json)
Check "refresh (rotates)" ($ref.refresh_token -ne $refresh)
$refresh = $ref.refresh_token

try { Invoke-RestMethod "$base/auth/login" -Method POST -ContentType application/json -Body (@{email=$email;password="wrong"}|ConvertTo-Json); Bad "login wrong password rejected" "accepted" }
catch { Check "login wrong password -> 401" ($_.Exception.Response.StatusCode.value__ -eq 401) }

Write-Host "`n== Taxonomy ==" -ForegroundColor Cyan
$cats = Invoke-RestMethod "$base/community/scam-types"
Check "scam-types seeded" ($cats.items.Count -ge 1) "count=$($cats.items.Count)"
$tags = Invoke-RestMethod "$base/community/tags"
Check "tags seeded" ($tags.items.Count -ge 1) "count=$($tags.items.Count)"

Write-Host "`n== Detection ==" -ForegroundColor Cyan
$det = Invoke-RestMethod "$base/detection" -Method POST -Headers $h -ContentType application/json -Body (@{text="URGENT: your bank account is suspended. Verify your password at http://bit.ly/x"}|ConvertTo-Json)
Check "text detection -> suspicious" ($det.verdict -eq "suspicious" -and $det.signals.Count -gt 0) "verdict=$($det.verdict)"
$checkId = $det.check_id

$benign = Invoke-RestMethod "$base/detection" -Method POST -Headers $h -ContentType application/json -Body (@{text="Hi, are we still meeting for lunch tomorrow at noon?"}|ConvertTo-Json)
Check "benign detection not suspicious" ($benign.verdict -ne "suspicious") "verdict=$($benign.verdict)"

$phone = Invoke-RestMethod "$base/detection/phone-number/trust-score?phone_number=%2B6591234567"
Check "phone trust (unseen=60)" ($phone.trust_score -eq 60 -and $phone.known -eq $false) "score=$($phone.trust_score)"

$myChecks = Invoke-RestMethod "$base/me/detection" -Headers $h
Check "GET /me/detection history" ($myChecks.items.Count -ge 2) "count=$($myChecks.items.Count)"

Write-Host "`n== Publish posts ==" -ForegroundColor Cyan
$body = @{ title="Fake DBS SMS"; redacted_text="Your DBS account is locked. Call 91234567 or verify at http://dbs-verify.xyz"; confirm_publication=$true } | ConvertTo-Json
$post = Invoke-RestMethod "$base/community/posts" -Method POST -Headers $h -ContentType application/json -Body $body
Check "create post" ($post.post_id -ne $null) 
Check "server re-scrubbed PII" ($post.redacted_text -notmatch "91234567") "text=$($post.redacted_text)"
Check "category assigned by classifier" ($post.category -ne $null -and $post.category.slug -eq "phishing") "category=$($post.category.slug)"
Check "tags assigned by classifier" ($post.tags.Count -ge 1) "tags=$($post.tags.Count)"
$postId = $post.post_id

# a second post for the feed
$body2 = @{ title="Prize scam call"; redacted_text="Congratulations you won a prize! Send a fee to claim."; confirm_publication=$true } | ConvertTo-Json
$post2 = Invoke-RestMethod "$base/community/posts" -Method POST -Headers $h -ContentType application/json -Body $body2

try { Invoke-RestMethod "$base/community/posts" -Method POST -Headers $h -ContentType application/json -Body (@{title="x";redacted_text="y";confirm_publication=$false}|ConvertTo-Json); Bad "post without confirmation rejected" "accepted" }
catch { Check "post w/o confirm -> 422" ($_.Exception.Response.StatusCode.value__ -eq 422) }

Write-Host "`n== Feed & detail ==" -ForegroundColor Cyan
$feed = Invoke-RestMethod "$base/community/feed"
Check "GET /community/feed" ($feed.items.Count -ge 2) "count=$($feed.items.Count)"
$search = Invoke-RestMethod "$base/community/feed/search?q=prize"
Check "feed search" ($search.items.Count -ge 1) "count=$($search.items.Count)"
$detail = Invoke-RestMethod "$base/community/posts/$postId" -Headers $h
Check "GET post detail" ($detail.post_id -eq $postId -and $detail.reactions -ne $null)
$mine = Invoke-RestMethod "$base/me/posts" -Headers $h
Check "GET /me/posts" ($mine.items.Count -ge 2) "count=$($mine.items.Count)"

Write-Host "`n== Reactions ==" -ForegroundColor Cyan
$rx = Invoke-RestMethod "$base/community/posts/$postId/reaction" -Method PUT -Headers $h -ContentType application/json -Body (@{vote=1}|ConvertTo-Json)
Check "upvote" ($rx.up_count -eq 1 -and $rx.my_vote -eq 1) "up=$($rx.up_count)"
$rx2 = Invoke-RestMethod "$base/community/posts/$postId/reaction" -Method DELETE -Headers $h
Check "remove vote" ($rx2.up_count -eq 0 -and $rx2.my_vote -eq 0)

Write-Host "`n== Comments ==" -ForegroundColor Cyan
$cmt = Invoke-RestMethod "$base/community/discussion/posts/$postId/comments" -Method POST -Headers $h -ContentType application/json -Body (@{body="I got this exact message too!"}|ConvertTo-Json)
Check "create comment" ($cmt.comment_id -ne $null -and $cmt.author_label -eq "Alice")
$commentId = $cmt.comment_id
$reply = Invoke-RestMethod "$base/community/discussion/posts/$postId/comments" -Method POST -Headers $h -ContentType application/json -Body (@{body="Same here, be careful";parent_id=$commentId}|ConvertTo-Json)
Check "create reply" ($reply.parent_id -eq $commentId)
$comments = Invoke-RestMethod "$base/community/discussion/posts/$postId/comments"
Check "list comments" ($comments.items.Count -ge 2) "count=$($comments.items.Count)"
$edited = Invoke-RestMethod "$base/community/discussion/comments/$commentId" -Method PATCH -Headers $h -ContentType application/json -Body (@{body="Edited: I received this too"}|ConvertTo-Json)
Check "edit own comment" ($edited.body -match "Edited")

Write-Host "`n== Flagging ==" -ForegroundColor Cyan
$flag = Invoke-RestMethod "$base/community/posts/$postId/flag" -Method POST -Headers $h -ContentType application/json -Body (@{reason="personal_information";details="still shows a phone number"}|ConvertTo-Json)
Check "flag post" ($flag.flag_id -ne $null -and $flag.status -eq "open")
try { Invoke-RestMethod "$base/community/posts/$postId/flag" -Method POST -Headers $h -ContentType application/json -Body (@{reason="spam"}|ConvertTo-Json); Bad "duplicate flag rejected" "accepted" }
catch { Check "duplicate flag -> 409" ($_.Exception.Response.StatusCode.value__ -eq 409) }

Write-Host "`n== Guidance & resources ==" -ForegroundColor Cyan
$g = Invoke-RestMethod "$base/guidance?scenario=sent_money"
Check "guidance (sent_money)" ($g.items.Count -ge 1 -and $g.items[0].resources.Count -ge 1) "count=$($g.items.Count)"
$res = Invoke-RestMethod "$base/guidance/resources?country=SG"
Check "resources catalog" ($res.items.Count -ge 1) "count=$($res.items.Count)"
$ro = $null
try { Invoke-RestMethod "$base/detection/$checkId/resource-opens" -Method POST -Headers $h -ContentType application/json -Body (@{resource_id=$res.items[0].id}|ConvertTo-Json); $ro=$true } catch { $ro=$false }
Check "record resource-open (metric)" $ro

Write-Host "`n== Moderation (needs moderator role) ==" -ForegroundColor Cyan
# register a plain user then elevate via DB-less path isn't possible over API; test 403 instead.
$reg2 = Invoke-RestMethod "$base/auth/register" -Method POST -ContentType application/json -Body (@{email=$modEmail;password="password123";display_name="Mod"}|ConvertTo-Json)
$h2 = @{ Authorization = "Bearer $($reg2.access_token)" }
try { Invoke-RestMethod "$base/moderation/queue" -Headers $h2; Bad "resident blocked from queue" "allowed" }
catch { Check "resident -> 403 on moderation" ($_.Exception.Response.StatusCode.value__ -eq 403) }

Write-Host "`n== Logout ==" -ForegroundColor Cyan
$lo = $null; try { Invoke-RestMethod "$base/auth/logout" -Method POST -ContentType application/json -Body (@{refresh_token=$refresh}|ConvertTo-Json); $lo=$true } catch { $lo=$false }
Check "logout" $lo

Write-Host "`n=================="
Write-Host "PASSED: $pass   FAILED: $fail" -ForegroundColor $(if($fail -eq 0){"Green"}else{"Red"})
if ($fail -gt 0) { exit 1 }
