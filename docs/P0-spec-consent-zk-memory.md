# P0 — Consent + Zero-Knowledge Memory (build spec)

> The smallest honest version of Bond Charter §6: **a Mox retains nothing without
> consent, and what it retains is encrypted under a key the operator never holds.**
> P0 is single-key, owner-held. Threshold custody, emergency contact, peer-pod
> recovery, and severance escrow are P1–P3 and explicitly out of scope here.
> Framework (OSS) reference implementation. Status: spec for review, 2026-06-15.

## 1. What P0 makes true (and what it doesn't)
**True after P0:**
- A Mox writes durable memory *only* with explicit per-item consent ("the gift").
- Everything retained is sealed with AEAD under a key the operator never receives.
- At rest and in transit, the operator/host holds only ciphertext it cannot read.
- Compelled disclosure yields ciphertext + "we do not hold the key."

**NOT solved by P0 (honest boundary — see §6):** protecting plaintext *during active
inference*, key recovery if the user loses their key, encrypted search, multi-device.

## 2. Threat model
- **In scope:** operator reading retained data at rest; host/storage compromise at
  rest; casual data-mining; compelled disclosure of stored data; accidental
  plaintext-to-disk.
- **Out of scope for P0:** a compromised brain *during* an unlocked session (plaintext
  is necessarily in RAM then — §6); key loss (P1 threshold); traffic analysis (P3).
- **Trust split:**
  - **Self-hosted** (user owns the compute): genuinely end-to-end — there is no operator.
  - **Hosted product:** ZK at rest + ephemeral in-use under zero-retention inference;
    confidential-computing (TEE) is the in-use hardening path (P1+).

## 3. Consent / gift protocol
- A Mox's durable memory is **opt-in per item.** Default memory is **ephemeral**
  (session-scoped, wiped at session end).
- To retain something durably, the Mox emits a **`retain` proposal**: `{summary, why,
  ttl?}`. The user approves or denies (one tap). Approve → sealed + logged as "gifted
  to <Mox> on <date>." Deny → discarded, never written.
- The consent checkpoint is **deterministic in the runtime**, not the model's
  discretion: durable plaintext can only be written through the consent path.
- **Standing consent** (e.g. "always remember my preferences") is allowed but recorded
  as an explicit scope the user can revoke; it never silently widens.

## 4. Cryptography (concrete)
- **AEAD:** XChaCha20-Poly1305 (libsodium `crypto_aead`); 192-bit random nonces.
- **Bond master key (KEK):** 256-bit, **held by the user**, established at bond setup as
  either (a) a device passkey / OS keystore key (preferred), or (b) passphrase →
  **Argon2id** (memory-hard) → KEK. The operator never receives the KEK.
- **Per-item DEK:** fresh random 256-bit per retained item; item encrypted with the DEK;
  the DEK is **wrapped** by the KEK. Stored: `{v, alg, nonce, ciphertext, wrapped_dek,
  wrap_nonce, meta}`. (DEK-per-item so one disclosure ≠ whole-store disclosure, and so
  individual items can be revoked/rotated.)
- **Unlock verifier:** store a verifier (e.g. a MAC of a known constant under the KEK)
  so a session can confirm a correct unlock **without** persisting the KEK. The KEK
  itself is never written to disk.

## 5. Lifecycle / flows
- **Bond setup:** establish the KEK (passkey or passphrase→Argon2id). Write the
  `verifier`. Nothing else.
- **Session unlock:** user provides passkey/passphrase → KEK reconstructed in the
  brain's **ephemeral memory** for the session (verified against `verifier`). Recall
  now works.
- **In session:** `recall` decrypts items in RAM as needed; `retain` (post-consent)
  seals new items. No durable plaintext ever.
- **Session end / lock:** zeroize KEK + any decrypted plaintext from memory. At rest =
  ciphertext only.

## 6. The in-use boundary (the crux — stated, not hidden)
To reason over your data a Mox must **decrypt it in memory**. On hosted infra that means
plaintext briefly lives in the operator's RAM during your session. P0's honest posture:
- **Never** logged, never persisted in the clear, wiped at session end.
- Runs under **zero-retention** inference (no training, no retention of prompts/outputs).
- **Hardening path (P1+):** confidential computing / TEE so even the host kernel cannot
  read brain RAM. **Self-hosting removes the issue entirely.**
- The charter states this verbatim: *"encrypted at rest under keys we don't hold;
  decrypted only in memory, only during your session, never logged or persisted in the
  clear."* We do not claim more.

## 7. Runtime integration (`runtime/mox_agent.py`)
- Extend the action protocol with `retain` (proposal → consent gate → seal) and `recall`
  (decrypt-in-memory). These join the existing reversible-only action allowlist.
- **Deterministic guardrail:** the runtime refuses to write durable plaintext by any
  path other than a consented `retain`. Sealing/unsealing is a library call, not a
  model behavior.

## 8. Data model (everything the host sees)
```
memory/
  items/<id>.sealed   # {v, alg, nonce, ciphertext, wrapped_dek, wrap_nonce,
                      #  meta:{created, ttl?, consent_ref, summary_hash}}
  index.sealed        # encrypted recall index (decrypted in RAM per session)
  verifier            # confirms a correct unlock; cannot derive the KEK
  consent-log.jsonl   # {id, when, scope} — NO plaintext content
```

## 9. Out of scope (P1–P3)
Threshold/Shamir custody · emergency contact · peer-pod recovery · severance tombstone ·
blind/searchable-encryption index · TEE/confidential-compute hardening · multi-device
key sync.

## 10. Open questions — please probe these
1. **Single-key risk.** P0 = lose your passphrase/passkey, lose your memory. Acceptable
   for a v1 (with a loud warning), or must P1 threshold ship before any launch?
2. **In-use exposure.** Is ZK-at-rest + zero-retention + ephemerality enough for v1, or
   is a TEE required before we make the §6 claim publicly?
3. **Index privacy.** Decrypt-the-index-in-RAM is fine functionally — but does holding a
   recall index (even encrypted) leak structure (item counts, sizes, timing)? Is a blind
   index needed sooner?
4. **Consent fatigue vs the gift model.** Asking before every retention nags; standing
   consent erodes "the gift." Where's the line?
5. **Operational config vs sovereign memory.** A MoxBus needs the business's hours,
   prices, etc. to function — is that operator-readable "config" (so the Mox works even
   locked) or ZK "gifted memory" (so it can't function until unlocked)? A **two-tier data
   classification** may be required. What goes in which tier?
6. **Locked-state usefulness.** If all memory is ZK and the user hasn't unlocked, can the
   Mox do anything useful? What's the degraded-but-safe behavior?
