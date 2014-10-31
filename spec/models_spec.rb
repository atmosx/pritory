# In Rspec-2.x '/spec' directory is loaded by default

# Load my configurations
require 'spec_helper'

describe 'User tests' do

  @user = User.create(username: 'test', password: 'pass')

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

describe 'Product tests' do
  u = User.create(username: 'test1', password: 'k')

  it 'create product' do
    expect(u.add_product(vat_category: '23', name: 'SomeProduct', barcode: '12345678910', cost: '3421', notes: 'Some Notes All Too Much').valid?).to eq(true)
  end

  it 'add 1st source price' do
    expect(u.products.last.add_source(name: 'Localstore1', price: '4564').valid?).to eq(true)
  end

  it 'add 2nd souce price' do
    expect(u.products.last.add_source(name: 'Localstore1', price: '5512').valid?).to eq(true)
  end

  it 'add 2nd source' do
    expect(u.products.last.add_source(name: 'Localstore2', price: '5512').valid?).to eq(true)
  end

  it 'add tag' do
    expect(u.products.last.add_tag(name: 'tag1').valid?).to eq(true)
  end

  it 'add tag2' do
    expect(u.products.last.add_tag(name: 'tag').valid?).to eq(true)
  end

  it 'updates product' do
    expect(u.products.last.update(name: 'NewNameProduct').valid?).to eq(true)
  end

  it 'can not delete product' do
    expect { u.products.last.destroy }.to raise_error
  end

  it 'sources are > 1' do
    expect(u.products.last.sources.count).to be > 1
  end

  it 'tags are > 1' do
    expect(u.products.last.tags.count).to be > 1
  end

  it 'remove all tags' do
    expect{ u.products.last.remove_all_tags }.to_not raise_error 
  end

  it 'delete product' do
    expect(u.products.last.delete.valid?).to eq(true)
  end
end

describe 'Settings' do

  # u = User.create(username: 'test2', password: 'k')

  # it 'modify settings' do
  #   expect(u.setting.update(email: 'some@email.com').valid?).to eq(true)
  # end
end
