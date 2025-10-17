# Development Workflow

## 🚀 Getting Started

### Prerequisites
- Ruby 3.0.0+
- PostgreSQL 12+
- Redis (for Sidekiq background jobs)

### Initial Setup
```bash
# Clone the repository (if not already done)
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
# In a separate terminal, start Sidekiq
bundle exec sidekiq
```

## 🔧 Development Commands

### Database
```bash
# Create and run migrations
rails generate migration AddFieldToModel
rails db:migrate

# Reset database (development only)
rails db:drop db:create db:migrate db:seed

# Open Rails console
rails console
```

### Testing
```bash
# Run all tests
bundle exec rspec

# Run specific test files
bundle exec rspec spec/models/user_spec.rb
bundle exec rspec spec/controllers/dashboard_controller_spec.rb

# Run tests with coverage
COVERAGE=true bundle exec rspec
```

### Code Quality
```bash
# Run RuboCop (when configured)
bundle exec rubocop

# Auto-fix RuboCop issues
bundle exec rubocop -a
```

## 🌿 Git Workflow

### Branch Naming
- `feature/description` - New features
- `fix/description` - Bug fixes
- `refactor/description` - Code refactoring
- `docs/description` - Documentation updates

### Commit Messages
Follow conventional commits:
- `feat: add new access template creation`
- `fix: resolve OAuth callback state validation`
- `refactor: extract OAuth service to base class`
- `docs: update README with setup instructions`

### Pull Request Process
1. Create feature branch from `main`
2. Make changes with descriptive commits
3. Run tests and ensure they pass
4. Create pull request with clear description
5. Request review from team members
6. Merge after approval and CI passes

## 🏗️ Architecture Guidelines

### Models
- Use UUID primary keys for all models
- Encrypt sensitive fields (tokens, secrets)
- Add proper validations and associations
- Include audit logging for important changes

### Controllers
- Keep controllers thin - delegate to services
- Use strong parameters for security
- Add proper authorization checks
- Handle errors gracefully

### Services
- Use dry-monads for error handling
- Make services idempotent where possible
- Include comprehensive logging
- Handle provider-specific logic in subclasses

### Background Jobs
- Use descriptive job names
- Include retry logic with exponential backoff
- Add proper error handling and logging
- Consider job priority and queue management

## 🔒 Security Considerations

### Development
- Never commit secrets or credentials
- Use environment variables for sensitive config
- Test OAuth flows thoroughly
- Validate all user inputs

### Testing
- Test security boundaries
- Verify token expiration logic
- Test OAuth callback security
- Validate encrypted data handling

## 📊 Monitoring & Debugging

### Logs
```bash
# View Rails logs
tail -f log/development.log

# View Sidekiq logs
tail -f log/sidekiq.log
```

### Debugging
```bash
# Rails console debugging
rails console
# Use binding.pry or debugger in code

# Check background jobs
rails console
# Sidekiq::Queue.new.size
```

## 🚀 Deployment

### Environment Setup
```bash
# Production environment variables
export RAILS_ENV=production
export DATABASE_URL=postgresql://...
export REDIS_URL=redis://...
export RAILS_MASTER_KEY=...
```

### Database Migrations
```bash
# Run migrations in production
rails db:migrate RAILS_ENV=production

# Backup database before major changes
pg_dump database_name > backup.sql
```

## 🧪 Testing Strategy

### Unit Tests
- Model validations and associations
- Service object logic
- Background job functionality
- Helper methods

### Integration Tests
- OAuth flow completion
- Background job processing
- Email delivery
- API endpoints

### System Tests
- Complete user workflows
- Cross-browser compatibility
- Mobile responsiveness
- Performance under load

## 📝 Documentation

### Code Documentation
- Document complex business logic
- Include examples for service usage
- Document API endpoints
- Keep README updated

### Architecture Decisions
- Document design decisions
- Record trade-offs and alternatives
- Update architecture diagrams
- Maintain production checklist

---

**Happy Coding! 🎉**

Remember to:
- Write tests for new features
- Follow security best practices
- Keep commits small and focused
- Update documentation as you go
- Ask questions when in doubt
