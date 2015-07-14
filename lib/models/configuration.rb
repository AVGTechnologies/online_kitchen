# == Schema Information
#
# Table name: configurations
#
#  id         :integer          not null, primary key
#  name       :string           default(""), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
require 'active_support'

class Configuration < ActiveRecord::Base
  has_many :machines, dependent: :destroy, inverse_of: :configuration
  belongs_to :user

  validates :name, presence: true, uniqueness: true, length: {minimum: 3}

  strip_attributes

  accepts_nested_attributes_for :machines, allow_destroy: true



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

  def destroy
    return super if destroyable?
    self
  end

  def schedule_destroy
    return self.destroy if machines.all?(&:deleted?)

    nested_result = machines.
      reject(&:deleted_or_destroy_queued?).
      map(&:schedule_destroy).
      any?

    nested_result ? update_attributes(deleted: true) : true
  end

  private

    def destroyable?
      return true if machines.all?(&:deleted?)
      errors.add(:base, "Cannot delete configuration with living machines")
      false
    end
end
