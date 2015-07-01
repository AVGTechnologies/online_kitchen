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

  strip_attributes

  def as_json(options = {})
    #TODO: set only proper attributes
    #see http://jonathanjulian.com/2010/04/rails-to_json-or-as_json/
    super(:include => [:machines])
  end

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
