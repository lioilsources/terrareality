# WireGuard tunnel: Hetzner app VM <-> DGX Spark (LLM gateway)

Production AI calls (attribute extraction, listing texts, chat search, vision tagging) go to the
AiStack LiteLLM gateway on the owner's DGX Spark (`infra/spark/README.md`). The Spark sits on the
owner's LAN behind NAT, so the tunnel is dialled from the Spark to the app VM's public IP
(UDP 51820, firewalled to `wireguard_peer_cidrs` in Terraform).

| | Hetzner app VM | DGX Spark |
|---|---|---|
| Tunnel address | `10.66.0.1/30` | `10.66.0.2/30` |
| Listens | UDP 51820 | nothing new (outbound only) |
| Allowed in the tunnel | replies only | TCP 8080 (LiteLLM) from `10.66.0.1` |

Prod env: `LLM_BASE_URL=http://10.66.0.2:8080/v1` for api, worker and vision. The operating rules
of the Spark still apply: routes down 07:00–13:00, max 4 parallel interactive requests, batch jobs
announced to the operator.

## Hetzner side (this repo)

1. `apt install wireguard-tools` (cloud-init already does it).
2. Generate keys and a pre-shared key; copy `wg0.conf.example` to `/etc/wireguard/wg0.conf`.
3. Send the operator the request below with **public** key and PSK (PSK over a secure channel).
4. Order after Docker (the PostUp rules use the `DOCKER-USER` chain):
   `mkdir -p /etc/systemd/system/wg-quick@wg0.service.d && printf '[Unit]\nAfter=docker.service\nRequires=docker.service\n' > /etc/systemd/system/wg-quick@wg0.service.d/after-docker.conf && systemctl daemon-reload`
5. After the operator confirms: `systemctl enable --now wg-quick@wg0`, `wg show`, then the
   `curl .../v1/models` check from the example file, and from a container:
   `docker compose exec vision python -c "import urllib.request;print(urllib.request.urlopen('http://10.66.0.2:8080/health/liveliness').status)"`.

## Request to the AiStack operator (we never touch the Spark)

> Hello, TerraReality production needs LAN-equivalent access to the LiteLLM gateway from Hetzner
> (no public Cloudflare endpoint). Please add a WireGuard peer on the Spark, with the owner's approval:
>
> ```
> [Interface]            # e.g. /etc/wireguard/terra.conf on the Spark
> Address = 10.66.0.2/30
> PrivateKey = <spark private key, generated on the Spark>
>
> [Peer]                 # TerraReality Hetzner app VM
> PublicKey = <hetzner.pub>
> PresharedKey = <psk, sent separately>
> Endpoint = <app_public_ipv4>:51820
> AllowedIPs = 10.66.0.1/32
> PersistentKeepalive = 25
> ```
>
> - Firewall on the Spark: allow only `10.66.0.1 -> tcp/8080` on that interface, nothing else
>   (no SSH, no other ports, no forwarding into the LAN).
> - LiteLLM must listen on the tunnel address too (or 0.0.0.0 with the firewall above).
> - Please send back the Spark public key. Routes used: `openclaw-default`, `shop-embed`
>   (on demand), `vl` (on demand), same as from the LAN today; same limits (4 parallel,
>   07:00–13:00 off).

Until the tunnel is up, production runs with `LLM_BASE_URL` empty (AI mock mode is NOT acceptable
for real users: switch the AI features off instead with `FEATURE_FLAGS=-ai.attributes,-ai.text,-ai.vision`, so no canned suggestions are shown).
