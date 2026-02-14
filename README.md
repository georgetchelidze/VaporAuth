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
