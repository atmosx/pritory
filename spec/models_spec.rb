# In Rspec-2.x '/spec' directory is loaded by default

# Load my configurations
require 'spec_helper'

before(:context) do
  User.create(username: 'test', password: 'pass')
end

describe "Model Tests" do

  it "creates user" do
    expect(User.new(username: 'new_user', password: 'password').valid?).to eq(true)
  end

  it "empty username" do
    expect(User.new(username: '', password: 'some').valid?).to eq(false)
  end

  it "user exists" do
    expect{User.create(username: 'test', password: 'some')}.to raise_error  
  end

  it "method login success" do
    expect(User.login_user_id('test', 'pass')).to_not eq(nil)
  end

  it "method login failure" do
    expect(User.login_user_id('test', 'pass_alt')).to eq(nil)
  end

  # CONTINUE WRITING TESTS HERE

  # it "update password" do #   ep
  # end
end
