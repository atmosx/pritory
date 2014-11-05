# Load my configurations
require 'spec_helper'

describe 'test helpers' do
  it 'turns numeric to euro' do
    expect(MyHelpers.cents_to_euro(1125)).to eq('11,25 €')
  end

  it 'turns euro to numeric' do
    expect(MyHelpers.euro_to_cents('24.32')).to eq(2432)
  end

  it 'get percentage' do
    expect(MyHelpers.numeric_to_percentage(0.1133)).to eq('11,33 %')
  end
end
