# In Rspec-2.x '/spec' directory is loaded by default

# Load my configurations
require 'spec_helper'

describe 'User tests' do

  User.create(username: 'test', password: 'pass')

  it 'creates user' do
    expect(User.new(username: 'new_user', password: 'password').valid?).to eq(true)
  end

  it 'empty username' do
    expect(User.new(username: '', password: 'some').valid?).to eq(false)
  end

  it 'user exists' do
    expect { User.create(username: 'test', password: 'some') }.to raise_error  
  end

  it 'method login success' do
    expect(User.login_user_id('test', 'pass')).to_not eq(nil)
  end

  it 'method login failure' do
    expect(User.login_user_id('test', 'pass_alt')).to eq(nil)
  end

  it 'delete user' do
    user = User.find(username: 'test')
    expect(user.delete.valid?).to eq(true)
  end
end

describe 'User settings' do
#   @user = User.create(username: 'test', password: 'pass')

  it 'create product' do
    a = 
    a = @user.add_product(vat_category: '23', name: 'SomeProduct', barcode: '12345678910', cost: '3421', notes: 'Some Notes All Too Much')
  end
end
