FactoryBot.define do
  factory :audit_event do
    auditable { nil }
    action { "MyString" }
    audit_changes { "MyText" }
    user { nil }
  end
end
