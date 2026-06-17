# License decision — RESOLVED: AGPL-3.0 + CLA (owner, 2026-06-14)

Research summary for picking the public Mox-Framework license. Decision is the
owner's; this records the evidence so it isn't re-litigated.

## Constraints
1. **Grant eligibility (hard):** target programs (AI Grant, Inference.net,
   E2B/FoundryLabs, AWS Agentic) require **OSI-approved "open source."** AWS's is
   explicit: *"organizations must have an OSI-approved license."*
2. **Open-core protection:** deter a cloud provider from reselling the framework
   as a managed service that undercuts the separate commercial product.

## Options

| License | OSI-approved (grant-safe) | Patent grant | Network copyleft | Resale deterrence |
|---|---|---|---|---|
| MIT | ✅ | ❌ | ❌ | none |
| Apache-2.0 | ✅ | ✅ (strong) | ❌ | none |
| **AGPL-3.0** | ✅ | ✅ | ✅ (§13) | moderate (forces source disclosure) |
| BSL / SSPL / Elastic v2 / FSL | ❌ | varies | varies | strong — but **fail grant eligibility** |

The source-available licenses (BSL/SSPL/ELv2/FSL) are **eliminated**: not
OSI-approved → would fail the grants. That leaves MIT / Apache-2.0 / AGPL-3.0.

## Recommendation: AGPL-3.0 + CLA + commercial dual-license
- **AGPL-3.0 is OSI-approved** → grant-eligible, *and* the only OSI license whose
  network-copyleft deters SaaS free-riding. Best open-core fit.
- **CLA from day one** (Apache-ICLA-style): contributors retain copyright by
  default, so without a CLA you cannot later sell a commercial license covering
  their code or relicense. A DCO does **not** grant relicensing rights.
- **The real moat is architectural:** the commercial product, private registry,
  and private network stay in **separate closed repos**, integrating with the
  AGPL framework only at arm's length (network/process, not in-process linking).
  A license only governs its own repo.

## The trade (flagged honestly)
Owner's initial lean was **Apache-2.0** (max adoption, best patent grant,
unambiguously grant-eligible — but **zero** resale protection; permissive
licensing is exactly what enabled cloud resale of Elasticsearch/Redis/etc.).
**AGPL-3.0** keeps grant eligibility *and* adds resale deterrence, at the cost of
some adoption friction (some enterprises, e.g. Google, ban AGPL dependencies).
For an open-core business whose moat is the commercial layer, that trade favors
AGPL. If framework ubiquity were the business, Apache would win.

## Before committing
1. Engineer the arm's-length boundary between AGPL framework and closed components.
2. Short legal review of CLA wording + the linking boundary. (Not legal advice.)

*Decision owner: the repo owner. Drafted from license research, 2026-06-14.*
