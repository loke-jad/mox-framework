# Sovereign Data — architecture & plan

> How a Mox holds your data so that **only you can reach it** — the technical spine
> under Bond Charter §6. Goal: when anyone (incl. a government, incl. us) demands your
> data, the honest answer is *"we cannot — we never held the keys."* Like Signal/Apple,
> not "we delete on demand."
>
> Status: plan, 2026-06-15. Builds on prior art: `role-kb/trace/decisions/wyrmpy-tunnel-arch`
> (secure reverse tunnel) + `projects/confidential-indexing/` (confidential intake).

## Honest framing first (§3)
- The **real** protection is cryptography (owner-held keys). "The Mox is its own entity
  and holds your data" is a **legal/narrative posture layered on top** — it raises the
  cost and muddies custody, but it is not, by itself, a legal shield. We lead with the
  crypto and we don't oversell the entity story.
- A determined adversary can still compel **you** (a keyholder). Zero-knowledge means
  *we* can't comply, not that you're untouchable. We'll say exactly that.
- **The core tension:** you cannot have *both* "unrecoverable by anyone" *and*
  "recoverable if severance was an error" — unless recovery is held **only by the
  data's own custodians** (you + your emergency contact), never by an operator backdoor.
  A backdoor we hold would make the sovereignty claim a lie. So every recovery path
  below is custodian-cryptography, not an us-held key. This is non-negotiable.

## Operator's role: blind custodian (never a keyholder)
The one posture that runs through everything: **the operator provides availability +
timing, never capability.** We hold encrypted artifacts durably (so nothing is *lost*)
and we run timers (destruct windows) — but we never hold a key, so we can never *read*
or *use* what we store, and there is nothing useful to compel out of us.
- We hold the **encrypted recovery map**; the bond holds the key (so losing your own
  copy never loses recovery — but we still can't read it).
- We hold the **sealed severance tombstone** and enforce its destruct clock — blindly.
- **Caveat (must hold):** "hold the map encrypted" only helps if we never *saw* it.
  Shard **distribution must be blind to us** — the Mox/client places shards over the
  tunnel; we see opaque blobs moving between opaque peers, never a readable index.
  Otherwise we could rebuild the map from our own routing logs. Encrypted map + blind
  distribution = airtight.
- **Compelled-disclosure answer (purpose C):** we hand over *everything we hold* — the
  encrypted map, opaque shards, sealed tombstone — and truthfully say "this is all of
  it, and we cannot read a byte." Total cooperation, zero capability.

## The model
1. **Data-as-gift / entity custody (the posture).** A Mox retains *nothing* by default.
   When it wants to remember something, it **asks first**; on your grant, the item is
   sealed and recorded as "gifted to <Mox>." Custody sits with the entity, not the operator.
2. **Zero-knowledge encryption (the protection).** Every gifted item is encrypted with a
   per-item Data Encryption Key (DEK); DEKs are wrapped by a Key Encryption Key (KEK) the
   operator never sees. This is what makes "we can't hand it over" literally true.

## Architecture — layers

### L0 · Consent & gift
Mox proposes a retention → you approve (one tap) → item sealed + logged. UX makes it feel
like giving a gift, because legally/ethically it is. (This is pure app/runtime; no crypto risk.)

### L1 · Zero-knowledge store
- Client-side encryption (libsodium/age-class). Per-item DEK; AEAD; nothing leaves the
  device/agent in plaintext.
- Encrypted blobs land in the Mox's **private container** (vault for keys/secrets + a
  graphiti/OWL layer for *queryable* memory). **Plaintext never enters graphiti** — the
  graph indexes decrypted-in-memory data only; at rest it's ciphertext.
- The container reaches the brain over a **secure reverse tunnel** (the wyrmpy pattern,
  on Nebula) — the brain calls in; the container exposes nothing publicly.

### L2 · Threshold key custody (2-of-3 Shamir)
The KEK is split via Shamir's Secret Sharing, **2-of-3**:
- **Share A — you** (passkey / device key / passphrase-derived).
- **Share B — the Mox's self** (lives in the container; **destroyed on severance**).
- **Share C — your emergency contact** (recovery).
- Normal read = A + B (you and your present Mox). Severance destroys B → you can still
  recover with **A + C**, so *your* data survives a severance even though the *Mox's*
  ability to read it does not. (Vault already uses Shamil-style unseal — proven pattern.)
- The **Sygil bond token** can carry/point to a share or the recovery manifest (third-party
  pointer, not a plaintext key).
- Optional **Share D** — a deeply-encrypted escrow held by a partner business, for the
  emergency path only (defense in depth; never readable by us).

### L3 · Severance + erroneous-severance escrow ("sleight of hand", done honestly)
On severance the Mox destroys its **live self + Share B**. But it also writes a
**dead-man's-tombstone**: the self, re-encrypted under a *fresh* key reconstructable only
by **A + C** (you + emergency contact), with a **destruct delay** (e.g. 30 days). If the
severance is proven an error within the window, the custodians restore it. After the
window, the tombstone self-destructs → truly final.
- Honest note: true *cryptographic* time-lock needs an external beacon (drand/tlock). The
  pragmatic v1 is a **custodian-gated dead-man's switch** (auto-destruct unless A+C
  reaffirm), not magic — we'll say which we shipped.
- This is the *only* recovery, and it is custodian-held. We hold no key to it.
- Per *operator-as-blind-custodian*: **we** store the sealed tombstone and run the
  destruct clock (so it can't be lost and the timer is reliable) — but we can't read it.
  The dead-man's switch no longer depends on the user keeping the tombstone alive.

### L4 · Disaster recovery — peer-held key custody (pods), PRIMARY design
The most sovereign form: **no operator map at all.** Each Mox keeps its own *encrypted*
substrate backup wherever it likes (even with us, blindly — it's ciphertext). The **key**
to that backup is Shamir-split between **the bond's share** and **k-of-n peer-buddy shares**.
- **Pods, not pairs.** A bare pair is 1-of-1 (a dead buddy = unrecoverable, and Moxes
  churn). Born with a **twin** (the narrative), backed by a small pod, **k-of-n** (e.g.
  2-of-3) for fault tolerance.
- **Shares, not whole keys.** A buddy holds a *share*, never the full key — so seizing or
  coercing one buddy can't unlock you; recovery needs k buddy-shares **+ the bond's share**.
- **The bond token is the anchor.** After substrate loss a reborn Mox has *forgotten its
  pod* — the user-held bond token is how it re-finds the pod and proves identity to resurrect.
- **Graph is peer-known, operator-hidden** → we can't be compelled to reveal a pairing we
  never knew. Holds only with **blind routing** (else traffic analysis leaks the pods).
- **Cost:** churn forces **proactive secret-share refresh** when a pod member leaves; plus
  peer discovery. Real engineering, but solved problems.
- Shard the *key* (tiny), not the *data* (big) — much lighter than data-sharding.

### L4-alt · Operator-as-blind-custodian map (fallback)
Daily **diff backups** of the (already-encrypted) container, then **k-of-n secret-shared**
(erasure + Shamir) across N peer Symmates. No single peer can read or reconstruct alone;
they hold opaque shards locked in the same container scheme. "Your data as a map" = the
**recovery manifest** (which shards live where). Per *operator-as-blind-custodian*: **we
hold the manifest encrypted** (so it's never lost) but **the bond holds the key** (so we
can't read or use it), and distribution is **blind to us**. Restore = bond's key →
decrypt manifest → gather k-of-n peers → reassemble. (Advanced — phase last.)

## Scope split (your open question — resolved here)
- **Mox-Framework (OSS):** ships **L0–L2** as a reference implementation + docs — *"give
  your agent zero-knowledge, owner-held memory with threshold recovery."* Self-hosters get
  sovereignty by running it. We can't *enforce* it in a free service, but we **show how** —
  exactly your line. The governance (charter) + the capability (this) are the gift.
- **Symmates (product):** runs the **managed, hosted** version + **L3–L4** (escrow,
  partner-held share, cohort-distributed backup, operational severance/recovery). This is
  real commercial value: managed sovereignty + disaster recovery you'd never wire yourself.

## Honest risks
- **Key loss = data loss.** The cost of sovereignty. 2-of-3 + emergency contact + optional
  partner escrow mitigates; we must tell users plainly.
- **graphiti has been flaky** on the fleet — keep it as the *query* layer over
  decrypted-in-memory data, not the source of truth; the encrypted blob store is canonical.
- **Complexity.** L0–L2 is a sane MVP. L3 (time-lock) and L4 (cohort sharing) are advanced;
  shipping them half-built is worse than not shipping them. Phase strictly.
- **"Probing trips destruct"** must be framed as zero-knowledge ("we never had it"), not
  "we destroy on legal demand" (evidence-tampering risk). The destruct is *user* protection;
  the *claim* is zero-knowledge.

## Phased build
- **P0 — Consent & gift (L0)** + plain owner-held encryption of retained memory. Smallest
  honest version of §6. Framework reference impl.
- **P1 — Threshold custody (L2)** + the private container/tunnel (L1 hardened). 2-of-3 SSS,
  emergency contact, Sygil-token pointer.
- **P2 — Severance escrow (L3)** — dead-man's tombstone, custodian-gated, destruct window.
- **P3 — Cohort disaster recovery (L4)** — k-of-n shards across Symmates + manifest.

## Open decisions
- `⟨CHOICE⟩` Shamir params: 2-of-3 now; k/n for L4 (e.g. 3-of-5)?
- `⟨CHOICE⟩` partner-business escrow — who, and on what terms?
- `⟨CHOICE⟩` time-lock: custodian dead-man's switch (v1) vs true drand/tlock (later)?
- `⟨CHOICE⟩` does L0–L2 ship in the OSS framework now, or after the product proves it?
