# P0 review — logic traps (synthesized)

> Two independent adversarial reviews (crypto/security lens + logic/abuse lens),
> 2026-06-15. They converged on the same blockers — high confidence. Deduped +
> prioritized below. "Both" = both reviewers flagged it independently.
>
> ⚠️ **PROCESS NOTE (Loke, 2026-06-15):** this review ran against the files *before*
> the agreed changes were written in. Some findings are **stale artifacts** of that:
> — **#2 severance contradiction** is already resolved by decision (severance destroys
>   the Mox's *access/share*; the user's data survives via their key + peer-pod). It only
>   appears because Charter §9 still has old wording. DISSOLVES on rewrite.
> — **#5 "probing trips destruct"** framing is already agreed → zero-knowledge wording.
> The crypto must-fixes (#6–#10), the operational-config tier (#3), single-key recovery
> (#4), in-use/TEE (#1), and the consent-model items (#11–#12) are **genuine and survive**.
> Correct sequence next time: apply agreed changes → THEN re-review.

## Meta-finding (the headline)
**The P0 spec is honest about its limits; the CHARTER overclaims relative to it.**
Spec §6/§10 carefully narrow the promise; Charter §6/§9 make *unconditional* claims P0
cannot keep on hosted infra. The single highest-value fix is to **align the charter's
claims down to the spec's honest boundaries (deployment-conditional) now** — before the
strong §6 claim is ever published. The `⟨CHOICE⟩` already on Charter §6 was right; these
findings show why it must stay soft for the hosted tier until TEE + threshold ship.

## 🔴 Blockers (both reviewers)

1. **Charter §6.2 overclaims "the operator cannot read it."** True only *at rest /
   no active session*. On hosted infra the KEK + plaintext are in the operator's RAM
   during every unlocked session; a compelled adversary just RAM-taps the next session.
   → **Fix:** make §6 deployment-conditional. Self-hosted = full claim. Hosted =
   "encrypted at rest under keys we don't hold; in active use, plaintext exists
   transiently in memory under zero-retention; TEE on the roadmap." (Promote spec §6's
   honest wording into the charter.)

2. **Severance model contradiction (CRITICAL).** Charter §9: data lives *only* in the
   Mox's self → severance sheds self → data "beyond reach," re-bond = blank. But P0/L3:
   data is under the *user's* key → survives severance (A+C recovery), user keeps it.
   These are incompatible. → **Fix:** severance destroys the *Mox's access* (its share),
   not the user's data. Reword §9: "the Mox's access is destroyed; your access persists
   via your key." Mark §9's destruction semantics "not in effect until P2."

3. **Operational-config trilemma (CRITICAL/HIGH).** A business Mox needs hours/prices to
   function. All-ZK → useless when locked (a customer talking to a locked MoxBus is a
   guaranteed flow). Operator-readable config → punctures §6. Always-unlocked → KEK in
   RAM forever (worst). → **Fix:** define an explicit, *disclosed* **public-operational
   tier** (operator-readable by design, structurally separated so customer/CRM data
   can't land in it), excluded from §6. Decide before any business Mox ships.

4. **Single-key loss = total memory loss, no P0 recovery, breaks §12 continuity.** A
   forgotten passphrase silently destroys everything; a warning won't save users. →
   **Fix:** default to passkey/OS-keystore (platform recovery), make raw passphrase an
   advanced option; OR require a recovery contact at setup (degenerate 1-of-1) before
   launch; OR hold the hosted launch for P1 threshold. Don't ship passphrase-only to
   non-technical bonds.

5. **"Probing trips destruct" (Charter §6.2) — no mechanism in P0, and the dangerous
   framing.** It's a P2 feature, and the only description is the evidence-tampering
   framing the plan itself says to avoid. → **Fix:** strike/soft-state it until P2; when
   shipped, frame strictly as zero-knowledge ("we never held it").

## 🟠 Crypto must-fixes (security reviewer — concrete)

6. **No AEAD associated-data binding** → items are swappable, replayable, downgradeable;
   `ttl`/`consent_ref`/`alg` are unauthenticated. → Bind `id|v|alg|consent_ref|created|ttl`
   as AD on the item AEAD; bind `id` into the DEK-wrap; reject unknown/old `alg` (no
   silent downgrade).
7. **The `verifier` is an offline passphrase-cracking oracle** (MAC of a *known*
   constant under a passphrase-derived KEK). → Drop the standalone verifier; confirm
   unlock by trial-decrypting a real wrapped DEK (the Poly1305 tag *is* the verifier).
   Passkey path avoids the oracle entirely.
8. **The recall `index.sealed` is a single point of total compromise** (its DEK reveals
   the whole store — undercuts the DEK-per-item rationale) and leaks counts/size/timing
   at rest; graphiti adds a plaintext-to-disk risk. → Encrypt index with its own
   AD-bound DEK; treat as the de-facto master record; pad/chunk; ensure graphiti has no
   write-back/swap/temp (tmpfs + mlock) or keep it off durable storage.
9. **consent-log + `summary_hash` + `scope` leak content/behavior in cleartext**
   (contradicts §6.1 "never silently mined"); a hash of a low-entropy summary is
   brute-forceable. → Seal the consent log; HMAC-under-KEK not bare hash; seal/coarsen
   `scope`. State plainly that retention *timing/volume* is observable unless padded.
10. **Nonce discipline + key rotation.** Mandate kernel CSPRNG (`randombytes_buf`),
    forbid userspace PRNGs; counter/`secretstream` for long-lived keys + the index.
    Define KEK rotation = re-wrap all DEKs (the wrap layer exists for this); store
    Argon2id params per-record so they can be raised; be honest that "revoke" =
    crypto-shred (keys destroyed, copies an adversary already took become inert), not
    "unmake copies."

## 🟡 Model / claim-scoping (both)

11. **"Deterministic consent gate" is procedural, not cryptographic** — only as strong
    as runtime integrity (on hosted = "trust the operator's binary," the thing ZK should
    remove); needs attestation (TEE) to be real. It also guarantees the *seal op*, not
    that the approved summary is faithful to what's sealed. → Scope the claim precisely;
    hash the *actual sealed payload* into the consent log and show the user the real item,
    not a model-authored gloss.
12. **Consent fatigue ⇄ standing consent** — per-item nags → rubber-stamp (cookie-banner
    failure); standing consent → silent retention (contradicts §6.1). → Separate the
    crypto guarantee (operator can't read it — lead with this) from the consent UX; use
    **periodic review** ("here are 6 things I remembered — keep/forget") + visible,
    bulk-revocable scopes. Keep "the gift" as flavor, not a load-bearing guarantee.
13. **"Self-hosted = no operator" is overstated** — inference still rides the rented
    frontier model under zero-retention even self-hosted. → Qualify: "no *hosting*
    operator for storage; inference rides the rented model under zero-retention."

## What this means
Almost everything is fixable by **scoping claims to the truth** + a focused crypto
hardening pass — not a redesign. The two genuine *design* decisions that must be made
(not just reworded) are **#3 (operational tier)** and **#4 (key-recovery before launch)**.
The strong public §6 claim should stay soft for the hosted product until **TEE
(in-use) + threshold (recovery)** ship.
