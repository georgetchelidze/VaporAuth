# VaporAuth

Standalone Vapor + Fluent auth package.

## What it includes
- `Auth` namespace (`auth` schema)
- Auth models under `Model/`
- Auth migrations under `Migration/`
- One-line registration helper: `AuthMigrations.register(on: app)`
- Auth routes:
  - `POST /auth/token` (`password`, `refresh_token` grants)
  - `GET /auth/me`
  - `POST /auth/logout`

## Usage
```swift
import VaporAuth

await AuthJWT.configure(on: app, secret: jwtSecret)
AuthMigrations.register(on: app)
AuthRoutes.register(on: app.routes)
```

Enable only selected routes:
```swift
AuthRoutes.register(
    on: app.routes,
    enabledRoutes: [.token, .me]
)
```

Configure security behavior:
```swift
AuthRoutes.register(
    on: app.routes,
    options: .init(
        accessTokenTTLSeconds: 3600,
        sessionLifetimeSeconds: 2_592_000,            // 30 days
        refreshTokenIdleTimeoutSeconds: 2_592_000,    // 30 days
        audience: "authenticated",
        issuer: "https://your-auth.example",
        confirmationPolicy: .requireConfirmedEmail,
        passwordGrantRateLimit: .init(
            maxAttempts: 10,
            windowSeconds: 60,
            blockSeconds: 300
        )
    )
)
```
