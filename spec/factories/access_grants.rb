FactoryBot.define do
  factory :access_grant do
    access_request { nil }
    integration_provider { nil }
    provider_account_id { "MyString" }
    access_token_encrypted { "MyText" }
    refresh_token_encrypted { "MyText" }
    token_expires_at { "2025-10-17 12:07:57" }
    status { "MyString" }
    assets { "MyText" }
  end
end
