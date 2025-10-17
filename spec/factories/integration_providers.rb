FactoryBot.define do
  factory :integration_provider do
    name { "MyString" }
    provider_type { "MyString" }
    base_url { "MyString" }
    client_id { "MyString" }
    client_secret_encrypted { "MyText" }
    oauth_authorize_url { "MyString" }
    oauth_token_url { "MyString" }
    scopes { "MyText" }
  end
end
