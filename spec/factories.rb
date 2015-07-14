FactoryGirl.define do

  factory :user do |f|
    f.sequence(:name)   { |n| "CZ\\Franta.Lopata#{n}" }
  end

  factory :configuration do |f|
    f.sequence(:name)   { |n| "configuration.name#{n}" }
    f.folder_name       "_online_kitnech_test"
    f.user              { FactoryGirl.create(:user) }
    f.factory :configuration_with_machines do
      f.machines        { build_list(:machine, 3) }
    end
  end

  factory :machine do |f|
    f.sequence(:name)   { |n| "test.name#{n}" }
    f.template          { ProviderTemplate.first }
  end

end
