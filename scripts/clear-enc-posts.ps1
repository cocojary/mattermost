Import-Module Posh-SSH -ErrorAction Stop

$VPS_IP = "103.146.23.11"
$VPS_PORT = 1401
$VPS_USER = "techzen"
$VPS_PASS = "Tech.ZEN@2026server"
$DEPLOY = "/opt/mattermost"

$secPass = ConvertTo-SecureString $VPS_PASS -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential($VPS_USER, $secPass)

$session = New-SSHSession -ComputerName $VPS_IP -Port $VPS_PORT -Credential $cred -AcceptKey -Force

# Chay lenh update database tren VPS
Write-Host "=== UPDATE ENCRYPTED POSTS TREN DB ===" -ForegroundColor Yellow
$r = Invoke-SSHCommand -SessionId $session.SessionId -Command "docker exec mattermost-db psql -U mmuser -d mattermost -c `"UPDATE posts SET message = '(Tin nhắn mã hoá không giải mã được)' WHERE message LIKE 'ENC:%';`""
Write-Host $r.Output

Remove-SSHSession -SessionId $session.SessionId
Write-Host "`nDone!" -ForegroundColor Green
