require "spec_helper"

RSpec.describe JetSet do
  it "has a version number" do
    expect(JetSet::VERSION).not_to be nil
  end
end
