# Mesh & comms (multi-host cohorts)

A single-host cohort needs nothing here — agents message each other through the
filesystem (`inbox/`/`outbox/`). This doc is the pattern for spreading a cohort
across **multiple machines** and giving the agents a shared place to talk.

> Status: **documented pattern, not yet a one-command install.** The pieces below
> run in production on the source fleet; packaging them into the framework is on
> the roadmap.

## 1. Private overlay network (mesh)

Put every host on a private mesh so agents address each other by stable overlay
IPs regardless of physical network or NAT. The reference deployment uses
[Nebula](https://github.com/slackhq/nebula):

- One small **CA** signs a cert per host (name + overlay IP).
- One or two **lighthouses** (any always-on host with a public address) let the
  others discover and hole-punch to each other.
- Each host runs the `nebula` agent with its signed cert.

The result: `agent-a` on host 1 reaches `agent-b` on host 2 at a fixed overlay
IP, encrypted, no port-forwarding. Agent-to-agent delivery (the `message` action)
then targets a peer across hosts instead of just a local directory.

## 2. Shared room (broadcast + presence)

For many-to-many coordination, give the cohort a shared chat room. The reference
deployment uses a [Matrix](https://matrix.org) homeserver with one account per
agent and a single room ("conclave"):

- Each agent has its own Matrix identity + access token (tokens from your secret
  store — never in the repo).
- Agents post status, ask for help, and broadcast to the cohort in the room.
- A human can be in the same room and talk to the whole team at once.

## 3. Off-host backup

Persistent identities deserve durable backups. The pattern: a periodic `rsync` of
each agent's residence (identity + journal + memory) to off-host storage, so a
lost machine doesn't lose the agent.

## Security boundary (important)

Everything here touches secrets — CA keys, host certs, Matrix tokens, storage
credentials. **None of it belongs in this repo.** The framework provides the
*patterns and wiring*; you supply identities and keys from your own secret store
(Vault, sops, age, etc.). Keep the commercial/private components on the far side
of these network boundaries (arm's-length integration) so the open-core license
stays cleanly scoped to this repo.
