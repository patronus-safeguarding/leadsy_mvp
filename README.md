# Leadsie MVP - Rails 7.1 Application

A production-grade Rails 7.1 MVP for managing client access to marketing accounts via secure links. This application enables agencies to request client authorization for Meta (Facebook/Instagram) and Google Ads accounts through a streamlined OAuth flow.

## 🏗️ Architecture Overview

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Agency User   │    │   Client User    │    │   Provider      │
│                 │    │                  │    │  (Meta/Google)  │
└─────────┬───────┘    └─────────┬────────┘    └─────────┬───────┘
          │                      │                       │
          │ 1. Create Template   │                       │
          ├─────────────────────→│                       │
          │                      │                       │
          │ 2. Create Request    │                       │
          ├─────────────────────→│                       │
          │                      │                       │
          │ 3. Send Link         │                       │
          ├─────────────────────→│                       │
          │                      │                       │
          │                      │ 4. Click Link         │
          │                      ├─────────────────────→│
          │                      │                       │
          │                      │ 5. OAuth Flow         │
          │                      ├─────────────────────→│
          │                      │                       │
          │                      │ 6. Callback           │
          │                      ├←─────────────────────│
          │                      │                       │
          │ 7. Grant Created     │                       │
          ├←─────────────────────│                       │
          │                      │                       │
          │ 8. Dashboard Update  │                       │
          ├─────────────────────→│                       │
```

## 🚀 Features

### Agency Side
- **Dashboard**: Overview of access requests, grants, and recent activity
- **Access Templates**: Create reusable templates with provider-specific scopes
- **Access Requests**: Manage client access requests with secure token generation
- **Access Grants**: Monitor and manage granted permissions
- **Client Management**: Maintain client database

### Client Side
- **Secure Links**: Time-limited, signed tokens for access requests
- **Approval Flow**: Simple interface to approve and authorize access
- **Provider Authorization**: Direct OAuth integration with Meta and Google
- **Transparency**: Clear visibility into what permissions are being granted

### Technical Features
- **UUID Primary Keys**: Secure, non-sequential identifiers
- **Encrypted Storage**: Sensitive data encrypted at rest
- **Background Jobs**: Token exchange and asset fetching via Sidekiq
- **Audit Trail**: Comprehensive logging of all actions
- **JSONB Fields**: Flexible storage for provider-specific data

## 🛠️ Tech Stack

- **Ruby**: 3.0.0
- **Rails**: 7.1.5
- **Database**: PostgreSQL with UUID support
- **Authentication**: Devise
- **Authorization**: Pundit (ready for implementation)
- **Background Jobs**: ActiveJob + Sidekiq
- **Styling**: Tailwind CSS
- **Templates**: Slim
- **Testing**: RSpec + FactoryBot
- **Service Objects**: Dry Monads for error handling

## 📋 Database Schema

### Core Models

#### User (Devise)
- Agency users with role-based access
- Fields: email, first_name, last_name, agency_name, is_owner

#### Client
- Client companies and contacts
- Fields: name, email, company, phone

#### IntegrationProvider
- OAuth provider configurations
- Fields: name, provider_type, client_id, client_secret_encrypted, oauth_urls, scopes

#### AccessTemplate
- Reusable permission templates
- Fields: name, description, provider_scopes (JSONB)

#### AccessRequest
- Individual client access requests
- Fields: token, expires_at, status, associations to template and client

#### AccessGrant
- Granted permissions per provider
- Fields: provider_account_id, access_token_encrypted, refresh_token_encrypted, assets (JSONB)

#### AuditEvent
- Activity logging
- Fields: auditable (polymorphic), action, audit_changes (JSONB), user

## 🔧 Installation

### Prerequisites
- Ruby 3.0.0+
- PostgreSQL 12+
- Redis (for Sidekiq)

### Setup
```bash
# Clone the repository
git clone <repository-url>
cd leadsie_mvp

# Install dependencies
bundle install

# Setup database
rails db:create
rails db:migrate
rails db:seed

# Start the application
rails server
```

### Background Jobs
```bash
# Start Sidekiq for background job processing
bundle exec sidekiq
```

## 🔐 Security Features

### Token Management
- **Signed Tokens**: All public links use signed, expiring tokens
- **Encrypted Storage**: Provider tokens encrypted using Rails 7.1 encryption
- **Token Rotation**: Background jobs handle token refresh
- **Expiration**: All tokens have configurable expiration times

### OAuth Security
- **State Parameter**: CSRF protection via signed state parameters
- **Callback Validation**: Secure callback handling with signature verification
- **Scope Validation**: Only requested scopes are granted

### Data Protection
- **Encrypted Attributes**: Sensitive fields encrypted at rest
- **Audit Logging**: All actions logged with user attribution
- **Access Control**: Role-based permissions ready for implementation

## 📊 API Endpoints

### Agency Routes (Authenticated)
```
GET    /dashboard                    # Dashboard overview
GET    /access_templates            # List templates
POST   /access_templates            # Create template
GET    /access_requests             # List requests
POST   /access_requests             # Create request
GET    /access_grants               # List grants
```

### Public Routes (No Authentication)
```
GET    /links/access_requests/:token # Client approval page
PATCH  /links/access_requests/:token/approve # Approve request
GET    /providers/meta?token=:token  # Meta OAuth redirect
GET    /providers/google?token=:token # Google OAuth redirect
GET    /providers/meta_callback      # Meta OAuth callback
GET    /providers/google_callback    # Google OAuth callback
```

## 🧪 Testing

The application includes comprehensive test coverage:

```bash
# Run all tests
bundle exec rspec

# Run specific test suites
bundle exec rspec spec/models/
bundle exec rspec spec/controllers/
bundle exec rspec spec/services/
bundle exec rspec spec/jobs/
```

### Test Coverage
- **Model Specs**: Validations, associations, enums
- **Request Specs**: Public token flow, OAuth callbacks
- **Service Specs**: Grant finalization idempotency
- **System Specs**: End-to-end user flows

## 🚀 Production Deployment

### Environment Variables
```bash
# Database
DATABASE_URL=postgresql://user:pass@host:port/dbname

# Redis
REDIS_URL=redis://host:port/0

# Encryption
RAILS_MASTER_KEY=your_master_key

# OAuth (replace with real values)
META_CLIENT_ID=your_meta_client_id
META_CLIENT_SECRET=your_meta_client_secret
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_CLIENT_SECRET=your_google_client_secret
```

### Production Checklist
See `PRODUCTION_TODO.md` for comprehensive production hardening checklist including:
- Secret management
- Token rotation
- Error handling
- Monitoring
- Compliance

## 🔄 Background Jobs

### TokenExchangeJob
- Exchanges short-lived tokens for long-lived tokens
- Provider-specific implementation
- Automatic retry with exponential backoff

### FetchAssetsJob
- Retrieves available assets (pages, ad accounts)
- Updates grant with accessible resources
- Enables asset-level permission management

## 📈 Monitoring & Observability

### Logging
- Structured logging for all OAuth flows
- Background job monitoring
- Error tracking and alerting

### Metrics
- Access request success rates
- Token refresh failures
- Background job performance

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For questions or support:
- Create an issue in the repository
- Email: support@leadsie.com
- Documentation: [Link to docs]

---

**Note**: This is an MVP implementation. See `PRODUCTION_TODO.md` for production hardening requirements.