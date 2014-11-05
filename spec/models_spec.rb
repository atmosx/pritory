# In Rspec-2.x '/spec' directory is loaded by default

# Load my configurations
require 'spec_helper'

describe User, 'tests' do

  before :all do 
    User.create(username: 'test', password: 'pass') if User.find(username: 'test').nil?
  end

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

describe Product, 'tests' do
  before :all do
    @user = User.create(username: 'user1', password: 'k')
  end

  it 'create product' do
    expect(@user.add_product(vat_category: '23', name: 'SomeProduct', barcode: '12345678910', cost: '3421', notes: 'Some Notes All Too Much').valid?).to eq(true)
  end

  it 'add 1st source price' do
    expect(@user.products.last.add_source(name: 'Localstore1', price: '4564').valid?).to eq(true)
  end

  it 'add 2nd souce price' do
    expect(@user.products.last.add_source(name: 'Localstore1', price: '5512').valid?).to eq(true)
  end

  it 'add 2nd source' do
    expect(@user.products.last.add_source(name: 'Localstore2', price: '5512').valid?).to eq(true)
  end

  it 'add tag' do
    expect(@user.products.last.add_tag(name: 'tag1').valid?).to eq(true)
  end

  it 'add tag2' do
    expect(@user.products.last.add_tag(name: 'tag').valid?).to eq(true)
  end

  it 'updates product' do
    expect(@user.products.last.update(name: 'NewNameProduct').valid?).to eq(true)
  end

  it 'can not delete product' do
    expect { @user.products.last.destroy }.to raise_error
  end

  it 'sources are > 1' do
    expect(@user.products.last.sources.count).to be > 1
  end

  it 'tags are > 1' do
    expect(@user.products.last.tags.count).to be > 1
  end

  it 'remove all tags' do
    expect{ @user.products.last.remove_all_tags }.to_not raise_error 
  end

  it 'delete product' do
    expect(@user.products.last.delete.valid?).to eq(true)
  end
end

# describe Setting, 'tests' do

#   before :each do 
#     @user = User.create(username: 'user', password: 'pass')
#   end

#   it 'modify email' do
#     expect(@user.setting.update(email: @email).valid?).to eq(true)
#   end

# end
