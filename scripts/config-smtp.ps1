Import-Module Posh-SSH -ErrorAction Stop

$VPS_IP = "103.146.23.11"
$VPS_PORT = 1401
$VPS_USER = "techzen"
$VPS_PASS = "Tech.ZEN@2026server"
$DEPLOY = "/opt/mattermost"

$secPass = ConvertTo-SecureString $VPS_PASS -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential($VPS_USER, $secPass)

$session = New-SSHSession -ComputerName $VPS_IP -Port $VPS_PORT -Credential $cred -AcceptKey -Force

# SMTP CONFIG
$smtpAuth = "true"
$smtpServer = "mail9024.maychuemail.com"
$smtpPort = "465"
$smtpUser = "tz-academy@techzen.vn"
$smtpPass = "eV2Hm4W9n3"
$smtpConnection = "TLS"

Write-Host "=== UPDATE SMTP CONFIG ===" -ForegroundColor Yellow
$r = Invoke-SSHCommand -SessionId $session.SessionId -Command @"
cd $DEPLOY
# Loai bo cau hinh SMTP cu (neu co)
sed -i '/^MM_SMTP_/d' .env
sed -i '/^MM_FEEDBACK_EMAIL=/d' .env
sed -i '/^MM_REPLY_EMAIL=/d' .env

# Them cau hinh SMTP moi
echo "" >> .env
echo "MM_SMTP_AUTH=$smtpAuth" >> .env
echo "MM_SMTP_SERVER=$smtpServer" >> .env
echo "MM_SMTP_PORT=$smtpPort" >> .env
echo "MM_SMTP_USER=$smtpUser" >> .env
echo "MM_SMTP_PASSWORD=$smtpPass" >> .env
echo "MM_SMTP_CONNECTION=$smtpConnection" >> .env
echo "MM_FEEDBACK_EMAIL=$smtpUser" >> .env
echo "MM_REPLY_EMAIL=$smtpUser" >> .env

grep MM_SMTP_ .env
"@
Write-Host $r.Output

Write-Host "`n=== RESTART MATTERMOST ===" -ForegroundColor Yellow
$r = Invoke-SSHCommand -SessionId $session.SessionId -Command @"
cd $DEPLOY
git fetch origin develop
git reset --hard origin/develop
docker compose -f docker-compose.prod.yml up -d --no-build mattermost
"@
Write-Host $r.Output

Remove-SSHSession -SessionId $session.SessionId
Write-Host "`nDone!" -ForegroundColor Green
