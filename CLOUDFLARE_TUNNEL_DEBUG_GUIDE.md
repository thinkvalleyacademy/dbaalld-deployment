🌐 Cloudflare Tunnel Debugging & Operations Guide

Domain: thinkvalleysoftwares.in
Tunnel Name: tvs-tunnel
Architecture: Cloudflare → Tunnel → Traefik → Nginx → Backend

1️⃣ Architecture Overview
User Browser
    ↓
Cloudflare Edge
    ↓
Cloudflare Tunnel (QUIC over 7844/443 outbound)
    ↓
cloudflared (running on server)
    ↓
localhost:4082 / 5082 / 6082
    ↓
Traefik → Nginx → Backend


⚠️ Important:

No public 80/443 required.

Tunnel works via outbound connection only.

2️⃣ Quick Health Check Commands (Run First)

When something breaks, run these in order:

sudo systemctl status cloudflared
cloudflared tunnel list
cloudflared tunnel info tvs-tunnel


Expected:

active (running)
Connections: 4


If connections = 0 → tunnel is offline.

3️⃣ Common Errors & Fixes
🔴 Error 1033 – Tunnel not connected

Symptom in browser:

Error 1033 – Cloudflare Tunnel error

Cause:

Tunnel not running or cannot connect to Cloudflare.

Fix:
sudo systemctl restart cloudflared
sudo systemctl status cloudflared


If still failing:

cloudflared tunnel run tvs-tunnel


Watch output.

You should see:

Registered tunnel connection


If not → outbound firewall issue.

🔴 DNS Already Exists (Error 1003)

When running:

cloudflared tunnel route dns tvs-tunnel domain.com

Error:
An A, AAAA, or CNAME record already exists

Fix:

Delete old A record in Cloudflare DNS first.
Then re-run route command.

🔴 Tunnel Credentials File Missing

Error:

Tunnel credentials file doesn't exist

Check config:
cat /etc/cloudflared/config.yml


Ensure:

tunnel: <UUID>
credentials-file: /home/<user>/.cloudflared/<UUID>.json


Check file exists:

ls ~/.cloudflared/


If missing:

cloudflared tunnel login
cloudflared tunnel create tvs-tunnel

🔴 Site loads but backend unreachable

Symptom:

Cloudflare works

502 or 504 error

Check:
curl http://localhost:4082
curl http://localhost:5082
curl http://localhost:6082


If failing → backend issue, not tunnel.

4️⃣ Verify Tunnel Connectivity

Run:

cloudflared tunnel info tvs-tunnel


You should see:

Connections:
  - del01
  - del04
  - ...


Multiple connections = healthy redundancy.

5️⃣ Check Logs

Live logs:

journalctl -u cloudflared -f


Important healthy message:

Registered tunnel connection


Problem signs:

Failed to connect
context deadline exceeded

6️⃣ Firewall Checklist

Tunnel requires outbound:

UDP 7844 (QUIC)

TCP 443 (fallback)

Ensure outbound is allowed:

sudo ufw status


Outbound should be ALLOW (default).

7️⃣ DNS Verification

Check record:

dig thinkvalleysoftwares.in +short


Should return:

<UUID>.cfargotunnel.com


If it returns public IP → tunnel not active in DNS.

8️⃣ Safe Restart Procedure

If tunnel misbehaves:

sudo systemctl stop cloudflared
sudo systemctl start cloudflared
sudo systemctl status cloudflared


Never restart repeatedly without checking logs.

9️⃣ Updating cloudflared

Check version:

cloudflared --version


Upgrade:

wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared-linux-amd64.deb
sudo systemctl restart cloudflared

🔟 Full Recovery Procedure (Worst Case)

If tunnel is completely broken:

sudo systemctl stop cloudflared
cloudflared tunnel delete tvs-tunnel
cloudflared tunnel create tvs-tunnel
cloudflared tunnel route dns tvs-tunnel thinkvalleysoftwares.in
sudo systemctl start cloudflared

1️⃣1️⃣ Security Best Practices

✔ Keep 80/443 closed on UFW
✔ Allow SSH only from your IP
✔ Keep Cloudflare proxy enabled (orange cloud)
✔ Do NOT expose server IP publicly
✔ Monitor tunnel connections weekly

1️⃣2️⃣ Monitoring Strategy

Minimum monitoring:

Cloudflare Analytics dashboard

UptimeRobot checking main + dev + preprod

cloudflared tunnel info weekly check

Professional monitoring:

Prometheus metrics via:

127.0.0.1:20241/metrics


Alert if tunnel connections drop below 1

1️⃣3️⃣ How to Test Tunnel Internally

Test backend without Cloudflare:

curl http://localhost:4082


Test tunnel DNS path:

curl https://thinkvalleysoftwares.in


If localhost works but domain fails → tunnel issue.

1️⃣4️⃣ Quick Decision Tree
Symptom	Likely Cause
1033	Tunnel not running
502	Backend down
DNS error	Wrong DNS record
Works locally, not externally	Cloudflare proxy misconfig
Tunnel running but no connections	Outbound firewall
1️⃣5️⃣ Final Stable Setup Checklist

✔ Tunnel running as service
✔ DNS CNAME to tunnel
✔ Ports 80/443 closed
✔ UFW outbound allowed
✔ Traefik listening on localhost only
✔ No A record pointing to server IP

🏁 Summary

Cloudflare Tunnel is stable if:

cloudflared is running

DNS points to tunnel

Outbound internet works

If those 3 are true → site works.

Everything else is backend or DNS layer.
