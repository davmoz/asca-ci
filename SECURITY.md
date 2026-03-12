# Security Best Practices for TFS Deployment

## RSA Key Management (key.pem)

- **Never commit `key.pem` to version control.** It is listed in `.gitignore`.
- Generate a fresh key for every deployment:
  ```bash
  openssl genrsa -out key.pem 2048
  ```
- Use at least 2048-bit keys for production (1024-bit is the minimum TFS supports).
- Restrict file permissions: `chmod 600 key.pem`
- Rotate keys periodically, especially if a compromise is suspected.

## MySQL / Database Security

- **Change the default MySQL credentials immediately.** The distribution config ships with an empty password.
- Use a strong, randomly generated password (20+ characters).
- Create a dedicated MySQL user for the TFS database with only the privileges it needs:
  ```sql
  CREATE USER 'tfs'@'127.0.0.1' IDENTIFIED BY '<strong-random-password>';
  GRANT SELECT, INSERT, UPDATE, DELETE ON forgottenserver.* TO 'tfs'@'127.0.0.1';
  FLUSH PRIVILEGES;
  ```
- Bind MySQL to `127.0.0.1` only (do not expose it to the internet).
- Enable MySQL's `general_log` during initial setup to audit queries, then disable it in production.

## Firewall Rules

Only the following ports need to be publicly accessible:

| Port | Protocol | Purpose |
|------|----------|---------|
| 7171 | TCP | Login server / status protocol |
| 7172 | TCP | Game server |

Recommended `iptables` rules:
```bash
# Allow login and game ports
iptables -A INPUT -p tcp --dport 7171 -j ACCEPT
iptables -A INPUT -p tcp --dport 7172 -j ACCEPT

# Rate-limit new connections to login port (anti-brute-force)
iptables -A INPUT -p tcp --dport 7171 -m connlimit --connlimit-above 5 -j DROP
iptables -A INPUT -p tcp --dport 7171 -m recent --set --name LOGIN
iptables -A INPUT -p tcp --dport 7171 -m recent --update --seconds 60 --hitcount 10 --name LOGIN -j DROP

# Drop everything else from the internet (adjust for SSH, etc.)
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -i lo -j ACCEPT
iptables -P INPUT DROP
```

Do **not** expose MySQL (3306), SSH (22), or any other service to the public internet unless explicitly needed and properly secured.

## DDoS Protection

- Use a provider with built-in DDoS mitigation (OVH Game DDoS Protection, Path.net, Cloudflare Spectrum).
- Enable SYN cookies: `sysctl -w net.ipv4.tcp_syncookies=1`
- Limit concurrent connections per IP using `connlimit` (see firewall rules above).
- Consider placing a TCP proxy or load balancer in front of the game server.
- Monitor bandwidth and connection counts; set up alerts for anomalies.

## Bot Detection

- Set `maxPacketsPerSecond` appropriately in `config.lua` (default: 25). Lower values catch more bots but may affect legitimate players on unstable connections.
- Enable `onePlayerOnlinePerAccount = true` to prevent multi-clienting.
- Monitor for abnormal behavior patterns:
  - Perfectly timed actions (potions, spells, movement).
  - 24/7 online players.
  - Repeated identical movement patterns.
- Consider implementing CAPTCHA challenges for suspicious accounts via Lua scripts.
- Log and review player actions server-side; do not rely on client-side validation.

## SQL Injection Prevention in Lua Scripts

TFS provides database escaping functions. **Always use them.**

**Bad (vulnerable):**
```lua
local name = player:getName()
db.query("SELECT * FROM players WHERE name = '" .. name .. "'")
```

**Good (safe):**
```lua
local name = player:getName()
db.query("SELECT * FROM players WHERE name = " .. db.escapeString(name))
```

Rules:
- Never concatenate raw user input into SQL queries.
- Always use `db.escapeString()` for string values.
- Always validate and cast numeric inputs with `tonumber()` before using them in queries.
- Avoid `db.query()` with player-controllable input when possible; use the C++ API methods instead.

## Rate Limiting

- `maxPacketsPerSecond = 25` -- Limits packets per client per second. Raise cautiously.
- `statusTimeout = 5000` -- Minimum milliseconds between status requests from the same IP.
- `loginProtocolPort` / `gameProtocolPort` -- Use firewall-level rate limiting (see above) in addition to application-level settings.
- Consider implementing login attempt tracking in Lua:
  - Lock accounts after N failed login attempts.
  - Add increasing delays between attempts.

## General Recommendations

- Keep TFS and all dependencies up to date.
- Run the server as a non-root user.
- Use filesystem permissions to protect config files: `chmod 600 config.lua key.pem`
- Enable logging and review logs regularly.
- Back up the database daily and test restores.
- Use TLS/SSL for any web-facing admin panels or APIs.
