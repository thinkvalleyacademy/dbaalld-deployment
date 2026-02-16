🌐 Adding a New Subdomain to Cloudflare Tunnel

Environment: thinkvalleysoftwares.in
Tunnel Name: tvs-tunnel

📌 Architecture Reminder
Browser
   ↓
Cloudflare DNS (CNAME → tunnel)
   ↓
Cloudflare Tunnel
   ↓
cloudflared (server)
   ↓
localhost:<port>
   ↓
Traefik → Docker


Important:

No public A record required

No public server IP used

DNS must point to tunnel

🟢 STEP 1 — Decide Where Traffic Should Go

You must decide the internal destination:

Example options:

Subdomain	Internal Service
app.example.com	http://localhost:80
 (Traefik)
admin.example.com	http://localhost:8080

api.example.com	http://localhost:9000

Recommended best practice:

👉 Always send to http://localhost:80
👉 Let Traefik route internally.

🟢 STEP 2 — Add Hostname to Tunnel Config

Edit:

sudo nano /etc/cloudflared/config.yml


Example:

ingress:
  - hostname: newsub.thinkvalleysoftwares.in
    service: http://localhost:80

  - service: http_status:404


If multiple domains exist, add above the final http_status:404.

Save.

🟢 STEP 3 — Restart Tunnel
sudo systemctl restart cloudflared


Verify:

sudo systemctl status cloudflared


Must show:

active (running)

🟢 STEP 4 — Create DNS Record for Subdomain

Run:

cloudflared tunnel route dns tvs-tunnel newsub.thinkvalleysoftwares.in


If successful, Cloudflare will create:

Type: CNAME
Name: newsub
Target: <tunnel-id>.cfargotunnel.com
Proxy: ON

🔴 If You Get Error 1003
An A, AAAA, or CNAME record already exists


Fix:

Go to Cloudflare → DNS

Delete existing A record

Run route command again

🟢 STEP 5 — Verify DNS

From server or local machine:

dig newsub.thinkvalleysoftwares.in +short


Expected:

<tunnel-id>.cfargotunnel.com


If empty → DNS not created.

🟢 STEP 6 — Verify Tunnel Connectivity

Run:

cloudflared tunnel info tvs-tunnel


Must show:

Connections: 4


If 0 → tunnel not connected.

🟢 STEP 7 — Verify Internally

Test internal routing:

curl -H "Host: newsub.thinkvalleysoftwares.in" http://localhost:80


If you get:

200 → good

401 → auth working

404 → Traefik router missing

Connection refused → wrong port

🟢 STEP 8 — Verify From Browser

Open:

https://newsub.thinkvalleysoftwares.in


Should load properly.

🧠 Troubleshooting Table
Symptom	Cause	Fix
NXDOMAIN	DNS record missing	Run tunnel route dns
1033 error	Tunnel not running	Restart cloudflared
502 error	Wrong localhost port	Fix config.yml
404 from Traefik	Router missing	Add Traefik router
Connection refused	Service not listening	Check internal port
🛡 Security Checklist

After adding subdomain:

✔ No A record pointing to server IP
✔ CNAME only
✔ Proxy enabled (orange cloud)
✔ Ports 80/443 closed in UFW
✔ Traefik protected with auth (if admin route)

🟢 Recommended Clean Design

Best long-term setup:

Tunnel config:

ingress:
  - hostname: *.thinkvalleysoftwares.in
    service: http://localhost:80
  - service: http_status:404


Then let Traefik handle all subdomain routing.

This removes need to edit tunnel config for every new subdomain.

Professional production approach.

📌 Final Quick Command Summary

Add subdomain:

sudo nano /etc/cloudflared/config.yml
sudo systemctl restart cloudflared
cloudflared tunnel route dns tvs-tunnel subdomain.thinkvalleysoftwares.in
dig subdomain.thinkvalleysoftwares.in +short
curl -H "Host: subdomain.thinkvalleysoftwares.in" http://localhost:80

🏁 Final Rule

Adding subdomain requires:

1️⃣ Tunnel ingress entry
2️⃣ DNS route
3️⃣ Traefik router

All three must exist.

If one is missing → it fails.
