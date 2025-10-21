# SyncGrant MVP Seed Data
# This file creates the essential data needed to run the application

puts "🌱 Seeding SyncGrant MVP data..."

# Create owner user
owner = User.find_or_create_by!(email: 'owner@grantsync.com') do |user|
  user.password = 'password123'
  user.password_confirmation = 'password123'
  user.first_name = 'John'
  user.last_name = 'Doe'
  user.agency_name = 'SyncGrant Agency'
  user.is_owner = true
end

puts "✅ Created owner user: #{owner.email}"

# Create integration providers
meta_provider = IntegrationProvider.find_or_create_by!(provider_type: 'meta') do |provider|
  provider.name = 'Meta (Facebook/Instagram)'
  provider.base_url = 'https://graph.facebook.com'
  provider.client_id = '786502037705097'
  provider.client_secret_encrypted = '811921fff4377bf862ca7460bae6d7f6'
  provider.oauth_authorize_url = 'https://www.facebook.com/v18.0/dialog/oauth'
  provider.oauth_token_url = 'https://graph.facebook.com/v18.0/oauth/access_token'
  provider.scopes = [
    'email',
    'public_profile',
    'business_management',
    'ads_management',
    'pages_manage_ads',
    'pages_read_engagement',
    'pages_show_list',
  ]
end

google_provider = IntegrationProvider.find_or_create_by!(provider_type: 'google') do |provider|
  provider.name = 'Google Ads'
  provider.base_url = 'https://googleads.googleapis.com'
  provider.client_id = '160764716455-djiojl21005prqtvm4jeu7jhdtdh3r58.apps.googleusercontent.com'
  provider.client_secret_encrypted = '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'
  provider.oauth_authorize_url = 'https://accounts.google.com/o/oauth2/v2/auth'
  provider.oauth_token_url = 'https://oauth2.googleapis.com/token'
  provider.scopes = [
    'https://www.googleapis.com/auth/adwords',
    'https://www.googleapis.com/auth/userinfo.email',
    'https://www.googleapis.com/auth/userinfo.profile'
  ]
end

puts "✅ Created integration providers: #{IntegrationProvider.count}"

# Create sample client
client = Client.find_or_create_by!(email: 'client@example.com') do |c|
  c.name = 'Jane Smith'
  c.company = 'Acme Corporation'
  c.phone = '+1-555-0123'
end

puts "✅ Created sample client: #{client.display_name}"

# Create access template
template = AccessTemplate.find_or_create_by!(name: 'Standard Marketing Access') do |t|
  t.user = owner
  t.description = 'Standard access template for marketing campaigns across Meta and Google'
  t.provider_scopes = {
    'meta' => [
      'email',
      'public_profile',
      'business_management',
      'ads_management',
      'pages_manage_ads',
      'pages_read_engagement',
      'pages_show_list',
    ],
    'google' => [
      'https://www.googleapis.com/auth/adwords',
      'https://www.googleapis.com/auth/userinfo.email',
      'https://www.googleapis.com/auth/userinfo.profile'
    ]
  }
end

# Update existing template with corrected scopes
template.update!(
  provider_scopes: {
    'meta' => [
      'email',
      'public_profile',
      'business_management',
      'ads_management',
      'pages_manage_ads',
      'pages_read_engagement',
      'pages_show_list',
    ],
    'google' => [
      'https://www.googleapis.com/auth/adwords',
      'https://www.googleapis.com/auth/userinfo.email',
      'https://www.googleapis.com/auth/userinfo.profile'
    ]
  }
)

puts "✅ Created access template: #{template.name}"

# Create sample access request
request = AccessRequest.find_or_create_by!(access_template: template, client: client) do |r|
  r.token = SecureRandom.urlsafe_base64(32)
  r.expires_at = 7.days.from_now
  r.status = 'pending'
end

puts "✅ Created access request for #{client.display_name}"

puts "🎉 Seeding complete!"
puts ""
puts "📋 Summary:"
puts "  • Owner user: #{owner.email} (password: password123)"
puts "  • Integration providers: #{IntegrationProvider.count}"
puts "  • Sample client: #{client.display_name}"
puts "  • Access template: #{template.name}"
puts "  • Access request: #{request.status}"
puts ""
puts "🔗 Sample access link: /links/access_requests/#{request.token}"
puts ""
puts "💡 Next steps:"
puts "  1. Run 'rails server' to start the application"
puts "  2. Login with #{owner.email} / password123"
puts "  3. Visit the access request to see the client flow"
