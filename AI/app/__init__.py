"""ScamWatch AI service — FastAPI app package.

The one process the Go backend talks to. Hosts PII removal (`/v1/pii/redact`)
and scam classification (`/v1/classify`), both backed by the clef-flash
decision model served by SGLang.
"""
