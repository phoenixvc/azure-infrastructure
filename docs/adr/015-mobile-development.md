# ADR-015: Mobile Development Strategy

## Status

Accepted

## Date

2025-12-07

## Context

The platform may require mobile applications to:
- Provide native mobile experiences for end users
- Access device capabilities (camera, GPS, notifications)
- Work offline with data synchronization
- Integrate with backend APIs and real-time services

We need a mobile development strategy that balances development efficiency, user experience, and maintainability across iOS and Android platforms.

## Decision Drivers

- **Code Reuse**: Maximize shared code between platforms
- **Performance**: Native-like performance and UX
- **Developer Productivity**: Time to market, team skills
- **Ecosystem**: Libraries, tooling, community support
- **Maintenance**: Long-term supportability
- **Backend Integration**: API consumption, real-time, offline sync

## Considered Options

### Cross-Platform Frameworks

1. **React Native**
2. **Flutter**
3. **Kotlin Multiplatform (KMP)**
4. **.NET MAUI**
5. **Ionic/Capacitor**

### Native Development

6. **Native iOS (Swift/SwiftUI) + Native Android (Kotlin/Compose)**

## Evaluation Matrix

| Criterion | Weight | React Native | Flutter | KMP | .NET MAUI | Ionic | Native |
|-----------|--------|--------------|---------|-----|-----------|-------|--------|
| Code Reuse | 5 | 4 (20) | 5 (25) | 4 (20) | 4 (20) | 5 (25) | 1 (5) |
| UI Performance | 5 | 4 (20) | 5 (25) | 5 (25) | 4 (20) | 3 (15) | 5 (25) |
| Native Access | 4 | 4 (16) | 4 (16) | 5 (20) | 4 (16) | 3 (12) | 5 (20) |
| Developer Pool | 4 | 5 (20) | 4 (16) | 3 (12) | 3 (12) | 4 (16) | 4 (16) |
| Learning Curve | 4 | 4 (16) | 4 (16) | 3 (12) | 4 (16) | 5 (20) | 2 (8) |
| Ecosystem | 4 | 5 (20) | 4 (16) | 3 (12) | 3 (12) | 4 (16) | 5 (20) |
| Hot Reload | 3 | 5 (15) | 5 (15) | 3 (9) | 4 (12) | 4 (12) | 2 (6) |
| App Size | 3 | 3 (9) | 3 (9) | 4 (12) | 3 (9) | 3 (9) | 5 (15) |
| Long-term Support | 4 | 4 (16) | 5 (20) | 4 (16) | 4 (16) | 3 (12) | 5 (20) |
| **Total** | **36** | **152** | **158** | **138** | **133** | **137** | **135** |

## Decision

**Tiered mobile strategy based on use case**:

| Use Case | Recommended | Alternative | Rationale |
|----------|-------------|-------------|-----------|
| Consumer apps (high UX) | Flutter | React Native | Best UX consistency, performance |
| Enterprise/internal apps | React Native | .NET MAUI | Large talent pool, fast iteration |
| Existing web team | React Native | Ionic | JavaScript/TypeScript skills transfer |
| Existing .NET team | .NET MAUI | Flutter | Leverage C# expertise |
| Existing Kotlin/Swift team | KMP or Native | Flutter | Leverage native expertise |
| Performance-critical | Native | Flutter | Maximum control |
| Prototype/MVP | Flutter | React Native | Fastest to market |

## Use Case Examples

### Example 1: B2C E-Commerce Mobile App

**Scenario**: Customer-facing shopping app with product catalog, cart, payments, push notifications, and offline browsing.

| Requirement | Priority | Framework Choice Impact |
|-------------|----------|------------------------|
| Smooth animations | High | Flutter excels with custom UI |
| Fast time-to-market | High | Flutter/React Native both good |
| Payment integration | High | All frameworks support |
| Offline catalog | Medium | All support, Flutter has good SQLite |
| Push notifications | High | All support via plugins |
| AR product preview | Medium | Native modules required in all |

**Recommendation**: **Flutter**

| Factor | Rationale |
|--------|-----------|
| UI consistency | Single rendering engine ensures pixel-perfect design |
| Performance | Compiled to native ARM, smooth 60fps animations |
| Offline | sqflite + drift for local database |
| State management | Provider/Riverpod/BLoC mature patterns |
| Testing | Widget testing enables high coverage |

**Backend Integration**:

| Integration | Approach |
|-------------|----------|
| REST API | dio or http package |
| Real-time | web_socket_channel or SignalR |
| Authentication | OAuth/OIDC via flutter_appauth |
| Push notifications | Firebase Cloud Messaging |
| Analytics | Firebase Analytics or App Insights |

### Example 2: B2B Field Service App

**Scenario**: Internal app for field technicians with offline-first data sync, document capture, signature collection, and integration with enterprise systems.

| Requirement | Priority | Framework Choice Impact |
|-------------|----------|------------------------|
| Offline-first | Critical | Need robust sync solution |
| Camera/document scan | High | Native access important |
| Signature capture | High | Canvas/drawing support |
| Enterprise SSO | High | Azure AD/Entra integration |
| Background sync | High | Platform-specific handling |
| MDM support | Medium | Native typically better |

**Recommendation**: **React Native** (or **.NET MAUI** for .NET shops)

| Factor | Rationale |
|--------|-----------|
| Enterprise integration | Strong Azure AD libraries |
| Offline sync | WatermelonDB or Realm for robust sync |
| Native modules | Large ecosystem for device access |
| Team familiarity | JavaScript skills common in enterprise |
| MDM compatibility | Good integration with Intune |

**Backend Integration**:

| Integration | Approach |
|-------------|----------|
| Offline sync | Azure Mobile Apps SDK or custom sync |
| Document storage | Azure Blob Storage with SAS tokens |
| Authentication | MSAL (Microsoft Authentication Library) |
| Background sync | React Native Background Fetch |
| Push notifications | Azure Notification Hubs |

## Framework Comparison by Criteria

### Code Sharing Percentage

| Framework | UI Code | Business Logic | Platform-Specific |
|-----------|---------|----------------|-------------------|
| Flutter | 95-100% | 95-100% | 0-5% |
| React Native | 85-95% | 90-95% | 5-15% |
| KMP | 0% (separate UI) | 70-90% | 10-30% |
| .NET MAUI | 90-95% | 95-100% | 5-10% |
| Native | 0% | 0-30% | 70-100% |

### Performance Characteristics

| Framework | Startup Time | Animation | Memory |
|-----------|--------------|-----------|--------|
| Native | Fastest | 60fps | Lowest |
| Flutter | Fast | 60fps | Medium |
| React Native | Medium | 60fps* | Medium |
| .NET MAUI | Medium | 60fps | Medium-High |
| Ionic | Slower | 30-60fps | Higher |

*React Native may drop frames in complex animations

### Backend Platform Considerations

| Backend | Best Mobile Match | SDK Quality |
|---------|-------------------|-------------|
| Azure | .NET MAUI, React Native | Excellent |
| AWS | React Native, Flutter | Good |
| GCP/Firebase | Flutter, React Native | Excellent |
| Self-hosted | Any | Varies |

## Alternative Cloud Platforms (Non-Azure)

When considering mobile backend services, evaluate these alternatives:

| Platform | Strength | Best For |
|----------|----------|----------|
| Firebase (GCP) | Real-time, auth, analytics | Startups, rapid development |
| AWS Amplify | Full-stack, GraphQL | AWS ecosystem users |
| Supabase | Open-source Firebase alternative | PostgreSQL preference |
| Appwrite | Self-hosted BaaS | Data sovereignty needs |

See ADR-016 for full cloud platform comparison.

## Consequences

### Positive

- Clear framework guidance per use case
- Flexibility to choose based on team skills
- Reduced duplicate development effort
- Consistent patterns for backend integration

### Negative

- Cross-platform may not achieve 100% native feel
- Native module development still required for some features
- Framework lock-in risk
- Different testing strategies per framework

### Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Framework deprecation | Low | High | Choose well-backed frameworks (Google, Meta) |
| Performance issues | Medium | Medium | Benchmark early, have native fallback plan |
| Skill gaps | Medium | Medium | Training investment, hiring strategy |
| OS version compatibility | Medium | Low | Follow framework update cadence |

## References

- Flutter documentation
- React Native documentation
- .NET MAUI documentation
- Kotlin Multiplatform documentation
- Mobile development best practices
