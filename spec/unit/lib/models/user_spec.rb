require 'spec_helper'

describe User do
  let!(:user) { User.new }
  subject { user }

  describe 'name' do
    it 'is present' do
      expect(subject.valid?).to be false
    end

    it 'does not contain non-literals' do
      user.update(name: 'petr.svetr!!!')
      expect(subject.valid?).to be false
    end

    it 'is not empty' do
      user.update(name: '')
      expect(subject.valid?).to be false
    end

    it 'can have UTF-8 characters' do
      pending 'support for this functionality not needed now'
      user.update(name: 'Zlatan Hrotič')
      expect(subject.valid?).to be true
    end

    it 'can have a dot' do
      user.update(name: 'petr.svetr')
      expect(subject.valid?).to be true
    end

    it 'can have a number' do
      user.update(name: 'petr.svetr2')
      expect(subject.valid?).to be true
    end

    it 'can have domain specified' do
      user.update(name: 'CZ\\petr.svetr')
      expect(subject.valid?).to be true
    end

    it 'can have a dash' do
      user.update(name: 'daniel.day-lewis')
      expect(subject.valid?).to be true
    end
  end
end
