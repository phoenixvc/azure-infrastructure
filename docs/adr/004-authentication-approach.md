# ADR-004: Authentication Approach

## Status

Accepted

## Date

2025-12-07

## Context

The API needs authentication to:
- Protect endpoints from unauthorized access
- Identify and track API consumers
- Enable rate limiting per client
- Support both machine-to-machine and user authentication

We need an authentication strategy that balances security, developer experience, and operational complexity.

## Decision Drivers

- **Security**: Strong authentication with proper credential management
- **Simplicity**: Easy to implement and use for API consumers
- **Flexibility**: Support multiple authentication methods
- **Azure Integration**: Leverage Azure AD where appropriate
- **Developer Experience**: Simple local development and testing

## Considered Options

1. **API Key Authentication**
2. **JWT (JSON Web Tokens)**
3. **Azure AD / Entra ID (OAuth 2.0)**
4. **mTLS (Mutual TLS)**
5. **Basic Authentication**

## Evaluation Matrix

| Criterion | Weight | API Key | JWT | Azure AD | mTLS | Basic Auth |
|-----------|--------|---------|-----|----------|------|------------|
| Implementation Simplicity | 4 | 5 (20) | 3 (12) | 2 (8) | 2 (8) | 5 (20) |
| Security Strength | 5 | 3 (15) | 4 (20) | 5 (25) | 5 (25) | 1 (5) |
| Azure Integration | 4 | 4 (16) | 4 (16) | 5 (20) | 3 (12) | 2 (8) |
| Stateless Operation | 4 | 5 (20) | 5 (20) | 4 (16) | 5 (20) | 5 (20) |
| Revocation Capability | 4 | 4 (16) | 2 (8) | 5 (20) | 4 (16) | 3 (12) |
| Client Onboarding | 4 | 5 (20) | 3 (12) | 2 (8) | 1 (4) | 5 (20) |
| Developer Experience | 4 | 5 (20) | 4 (16) | 3 (12) | 2 (8) | 4 (16) |
| Rate Limiting Support | 3 | 5 (15) | 4 (12) | 4 (12) | 3 (9) | 3 (9) |
| **Total** | **32** | **142** | **116** | **121** | **102** | **110** |

### Scoring Guide
- **Weight**: 1 (Nice to have) → 5 (Critical)
- **Score**: 1 (Poor) → 5 (Excellent)

## Decision

**Tiered authentication approach**:

1. **Primary**: API Key authentication for service-to-service communication
2. **Enhanced**: JWT support for user-context operations (optional)
3. **Enterprise**: Azure AD integration for corporate deployments

## Rationale

API Key as primary authentication:

1. **Simplest integration**: Single header/query parameter, no token management.

2. **Immediate revocation**: Key can be rotated or disabled instantly in Key Vault.

3. **Easy debugging**: Clear authentication without token decoding.

4. **Rate limiting friendly**: Direct mapping of key to client for quotas.

5. **Development mode**: Can be disabled for local development.

### When to Use Each Method

| Scenario | Authentication Method |
|----------|----------------------|
| Internal service-to-service | API Key |
| Third-party integrations | API Key with scopes |
| User-facing mobile/web apps | JWT with Azure AD B2C |
| Enterprise SSO | Azure AD / Entra ID |
| High-security scenarios | mTLS + API Key |

## Consequences

### Positive

- Simple implementation and maintenance
- Easy to rotate and manage keys via Key Vault
- Clear audit trail per API key
- No external token service dependency
- Works with all HTTP clients

### Negative

- Keys don't expire automatically (need rotation policy)
- No built-in user context (add JWT layer if needed)
- Must be transmitted securely (HTTPS required)
- Each client needs unique key management

### Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Key exposure in logs | Medium | High | Never log keys, use masking |
| Key leakage | Medium | High | Store in Key Vault, rotate regularly |
| Brute force attacks | Low | Medium | Rate limiting, key complexity |
| No user context | N/A | Low | Add JWT layer for user operations |

## Implementation Notes

### API Key Authentication

```python
# Header-based (preferred)
X-API-Key: your-api-key-here

# Query parameter (fallback)
GET /api/v1/items?api_key=your-api-key-here
```

### Configuration

```python
# settings
api_key: Optional[str] = None  # None = auth disabled (dev mode)
```

### Middleware Usage

```python
from app.middleware import APIKeyAuth

auth = APIKeyAuth()

@router.get("/protected")
async def protected_route(key: str = Depends(auth)):
    return {"authenticated": True}
```

### Key Management

```bicep
// Store API keys in Key Vault
module keyVault 'modules/key-vault/main.bicep' = {
  params: {
    secrets: {
      'api-key-client-a': generateUniqueString('client-a', subscription().id)
      'api-key-client-b': generateUniqueString('client-b', subscription().id)
    }
  }
}
```

### Extending to JWT

For user authentication, add JWT validation:

```python
from app.middleware import JWTAuth

jwt_auth = JWTAuth(
    issuer="https://login.microsoftonline.com/{tenant}/v2.0",
    audience="api://your-api-id"
)

@router.get("/user-data")
async def user_route(user: User = Depends(jwt_auth)):
    return {"user_id": user.id}
```

## References

- [API Security Best Practices](https://owasp.org/www-project-api-security/)
- [Azure Key Vault](https://docs.microsoft.com/azure/key-vault/)
- [Microsoft Identity Platform](https://docs.microsoft.com/azure/active-directory/develop/)
