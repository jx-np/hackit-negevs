# Seeds realistic demo content via the API so the frontend has data to work with.
# Idempotent-ish: safe to run on a fresh DB. Creates demo users, posts, comments,
# reactions, and flags. Run AFTER seed.sql (taxonomy) and with the server running.
$ErrorActionPreference = "Stop"
$base = "http://localhost:8080/api/v1"

function Register($email, $name) {
    try {
        $r = Invoke-RestMethod "$base/auth/register" -Method POST -ContentType application/json -Body (@{email=$email;password="password123";display_name=$name}|ConvertTo-Json)
        return $r.access_token
    } catch {
        $r = Invoke-RestMethod "$base/auth/login" -Method POST -ContentType application/json -Body (@{email=$email;password="password123"}|ConvertTo-Json)
        return $r.access_token
    }
}

$alice = Register "alice@demo.sg" "Alice Tan"
$bob   = Register "bob@demo.sg" "Bob Lim"
$carol = Register "carol@demo.sg" "Carol Ng"
Register "moderator@demo.sg" "Mod Team" | Out-Null  # elevated to moderator via SQL separately
$ha = @{ Authorization = "Bearer $alice" }
$hb = @{ Authorization = "Bearer $bob" }
$hc = @{ Authorization = "Bearer $carol" }

function Post($h, $title, $text, $tags) {
    # scam_type is not client-supplied: the backend classifier assigns the category.
    $body = @{ title=$title; redacted_text=$text; tags=$tags; confirm_publication=$true } | ConvertTo-Json
    return (Invoke-RestMethod "$base/community/posts" -Method POST -Headers $h -ContentType application/json -Body $body).post_id
}

$p1 = Post $ha "Fake DBS 'account locked' SMS" "Your DBS account has been locked due to suspicious activity. Verify now at http://dbs-secure-login.xyz or call 91234567." @("bank-impersonation","suspicious-link")
$p2 = Post $hb "WhatsApp job offer, too good to be true" "Earn `$300/day working from home! Just pay a `$50 registration fee to start. Transfer to this PayNow." @("money-request")
$p3 = Post $hc "Fake parcel delivery (SingPost)" "Your parcel is held at customs. Pay a small fee to release it: http://singpost-redelivery.top" @("delivery-scam","suspicious-link")
$p4 = Post $ha "Investment group promising 20% weekly" "Join our exclusive crypto group. Guaranteed 20% returns weekly. Limited slots!" @("money-request")
$p5 = Post $hb "Lucky draw prize call" "Congratulations! You have won `$5000 in the national lucky draw. Provide your bank details to claim." @("prize-scam")

# Reactions
Invoke-RestMethod "$base/community/posts/$p1/reaction" -Method PUT -Headers $hb -ContentType application/json -Body (@{vote=1}|ConvertTo-Json) | Out-Null
Invoke-RestMethod "$base/community/posts/$p1/reaction" -Method PUT -Headers $hc -ContentType application/json -Body (@{vote=1}|ConvertTo-Json) | Out-Null
Invoke-RestMethod "$base/community/posts/$p3/reaction" -Method PUT -Headers $ha -ContentType application/json -Body (@{vote=1}|ConvertTo-Json) | Out-Null

# Comments
$c1 = (Invoke-RestMethod "$base/community/discussion/posts/$p1/comments" -Method POST -Headers $hb -ContentType application/json -Body (@{body="I got the exact same SMS yesterday. DBS never asks you to verify via a link."}|ConvertTo-Json)).comment_id
Invoke-RestMethod "$base/community/discussion/posts/$p1/comments" -Method POST -Headers $hc -ContentType application/json -Body (@{body="Thanks for sharing, reported to ScamShield.";parent_id=$c1}|ConvertTo-Json) | Out-Null
Invoke-RestMethod "$base/community/discussion/posts/$p3/comments" -Method POST -Headers $ha -ContentType application/json -Body (@{body="The real SingPost domain is singpost.com, not .top!"}|ConvertTo-Json) | Out-Null

# A flag for the moderation queue
Invoke-RestMethod "$base/community/posts/$p2/flag" -Method POST -Headers $hc -ContentType application/json -Body (@{reason="spam";details="Looks like a recruitment scam"}|ConvertTo-Json) | Out-Null

Write-Host "Demo data seeded: 5 posts, reactions, comments, 1 flag." -ForegroundColor Green
