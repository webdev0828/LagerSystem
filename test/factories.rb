FactoryGirl.define do

  # This will guess the User class
  factory :user do
    sequence(:username) { |n| "user#{n}" }
    email { |u| "#{u.username}@jn-spedition.dk" }
    full_name { Faker::Name.name }
    phone     { Faker::PhoneNumber.phone_number }
    password  { Faker::Lorem.characters(10) }
    department_ids [1,2]
    role 'default'
  end

  factory :customer do
    name    { Faker::Company.name }
    number  { Faker::Number.number(8).to_s }
    subname { Faker::Company.name }
    address { Faker::Address.street_address }
    phone   { Faker::PhoneNumber.phone_number }
    fax     { Faker::PhoneNumber.phone_number }
    email   { Faker::Internet.email }

    trait :with_department do
      association :department
    end

    # Do not set department_id!
    # This should be done from tests
  end

  factory :department do
    name { Faker::Lorem.words(2).join(' ') }
    label { |d| d.name.to_s[/\w+/] }
    address { Faker::Address.street_address }
    authorization_number { Faker::Number.number(20) }

    association :lobby, factory: :bulk_storage

  end

  factory :interval do
    to { Time.now }
    from { |i| i.to - 1.week }
  end

  factory :bulk_storage do
    name { Faker::Lorem.words(2).join(' ') }
  end

  factory :organized_storage do
    name { Faker::Lorem.words(2).join(' ') }

    # ignore
    transient do
      shelf_count  2
      column_count 2
      floor_count  2
    end

    after(:create) do |os, e|
      (1..e.shelf_count).each do |s|
        (1..e.column_count).each do |c|
          (1..e.floor_count).each do |f|
            os.placements.create(:shelf => s, :column => c, :floor => f, :organized_storage => os)
          end
        end
      end
    end

  end

  factory :arrangement do
    use_scrap true
    use_scrap_minimum true
    scrap_minimum { 1 + rand(10) }
  end

  factory :arrival do
    temperature { -20 + rand(5) }
    arrived_at { 1.minute.ago }
    count { 1 + rand(60) }
    pallet_type_id { 1 }
    capacity { 1 + rand(30) }
    weight { 0.42 }
    number { Faker::Number.number(10) }
    batch { Faker::Number.number(12) }
    name { Faker::Lorem.sentence }
    # trace { Faker::Number.number(30) }
    best_before { 100.days.from_now }
  end

end