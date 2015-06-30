# == Schema Information
#
# Table name: configurations
#
#  id         :integer          not null, primary key
#  name       :string           default(""), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Configuration < ActiveRecord::Base
  has_many :machines, inverse_of: :configuration
  belongs_to :user

  validates :name, presence: true, uniqueness: true, length: {minimum: 3}
  validates :user, presence: true, uniqueness: true, length: {minimum: 7}

  strip_attributes

  def state
    states = machines.pluck(:state).uniq

    case states
      when ['ready']
        'ready'
      when ['destroy_queued']
        'destroy_queued'
      else
        'updating'
    end
  end
end
