FactoryBot.define do
  factory :access_request do
    access_template { nil }
    client { nil }
    token { "MyString" }
    expires_at { "2025-10-17 12:07:47" }
    status { "MyString" }
  end
end
