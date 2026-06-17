# Auth — how a bond logs in to its Symmate (hosted product)

Draft, 2026-06-15. Passwordless + risk-based, with the bond's conversational
recognition layered on top.

## Two assurance levels
- **Chat (low bar):** talk to your Symmate. Magic-link session + device cookie is enough.
- **Owner panel (high bar):** major config / charter-bounded settings. Requires a HARD
  factor + passes the conversational challenge. Step-up always required here.

## Factors
- **Primary (passwordless):** magic-link via **email + SMS**.
- **Hard factors (gate the owner panel):** platform biometrics — **face + fingerprint**
  via passkey/WebAuthn — and **TOTP**. Multiple, as fallbacks.
- **Soft signal — the bond recognizes you:** how you speak/type/sound/chat, plus
  conversational questions referencing your **recent chats**. Part of the bond's feel.
- **Context signals:** IP / geo / browser / device fingerprint, logged every session.

## Risk engine
Context signals feed a risk score. Familiar device + location → smooth. Anomaly
(new device/country/etc.) → **step up**: more conversational questions + a hard factor
before anything sensitive. Uncertain → escalate further; never silently allow.

## Honest caveat (important)
The conversational/stylometric layer is a **signal, not a lock** — text style is
spoofable (anyone can have an LLM mimic you), and it false-rejects. Use it to *raise or
lower friction* in the risk engine and as brand-fit UX ("your Mox knows you"), **never as
the sole gate** for the owner panel. The real gate is the hard factors (passkey
biometric / TOTP / magic-link).
