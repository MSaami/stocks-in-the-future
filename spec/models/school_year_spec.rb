require 'rails_helper'

RSpec.describe SchoolYear, type: :model do
  it "has a valid factory" do
    expect(FactoryBot.build(:school_year)).to be_valid
  end
end
