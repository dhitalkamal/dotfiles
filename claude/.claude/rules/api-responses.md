---
paths:
  - "**/views.py"
  - "**/serializers.py"
  - "**/viewsets.py"
  - "**/urls.py"
  - "**/api/**"
---

# API responses

Validate all input via DRF serializers before touching business
logic. Never trust unvalidated request data.

Response shape, always:

{
  "status": "...",
  "timestamp": "<ISO 8601>",
  "data": <T> | null,
  "errors": [ { "code": "...", "message": "...", "details": <any> } ],
  "meta": { "service": "...", "version": "v1", ... }
}

- status: machine-readable outcome, e.g. "success" or "error".
- timestamp: ISO 8601, server time the response was generated.
- data: the payload on success, null on error.
- errors: empty array on success. On failure, one entry per error:
  code (short machine-readable slug, e.g. "validation_error"),
  message (human-readable), details (DRF's native field-error dict,
  other structured context, or null).
- meta: service (a real, descriptive service name, e.g. "Auth
  Service" - not a slug like "rt-auth-service"), version (API
  version, e.g. "v1"), plus pagination fields (count, next,
  previous) when data is a list.

Status codes:
- 200: successful GET/PUT/PATCH.
- 201: successful POST that created a resource.
- 204: successful DELETE, or an update with no body to return.
- 400: serializer validation failed, or the request is malformed -
  DRF's own default for ValidationError, so don't fight it with 422.
- 401: missing or invalid credentials.
- 403: valid credentials, action not permitted.
- 404: resource doesn't exist, or hidden from this user for privacy.
- 409: conflict with current state (duplicate unique field, stale
  update).
- 500: reserved for genuinely unexpected server faults only. Never
  for something a serializer should have caught.
