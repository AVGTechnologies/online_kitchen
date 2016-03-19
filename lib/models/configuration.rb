# == Schema Information
#
# Table name: configurations
#
#  id          :integer          not null, primary key
#  name        :string           default(""), not null
#  folder_name :string
#  user_id     :integer
#  deleted     :boolean          default(FALSE), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

require 'active_support'

# Configuration representation
class Configuration < ActiveRecord::Base
  has_many :machines, dependent: :destroy, inverse_of: :configuration
  belongs_to :user

  validates :name,
            presence: true,
            uniqueness: true,
            length: { minimum: 3, maximum: 32 },
            format: {
              with: /\A[A-Za-z0-9_. ]+\z/,
              message: 'only allows letters, digits, dot and underscore'
            }
  validate :folder_name_did_not_change

  strip_attributes

  accepts_nested_attributes_for :machines, allow_destroy: true

  before_create :copy_name_to_config

  scope :empty_configurations, lambda {
    where('id NOT IN (SELECT DISTINCT(configuration_id) FROM machines)')
  }

  def as_json(options = {})
    # TODO: set only proper attributes
    # see http://jonathanjulian.com/2010/04/rails-to_json-or-as_json/

    result = super(options)
    result['machines_attributes'] = machines.as_json
    result
  end

  def state
    states = machines.map(&:state).uniq

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
    return destroy if machines.all?(&:deleted?)

    nested_result = machines
                    .reject(&:deleted_or_destroy_queued?)
                    .map(&:schedule_destroy)
                    .any?

    nested_result ? update_attributes(deleted: true) : true
  end

  def copy_name_to_config
    self.folder_name = name
  end

  private

  def destroyable?
    return true if machines.all?(&:deleted?)
    errors.add(:base, 'Cannot delete configuration with living machines')
    false
  end

  def folder_name_did_not_change
    # note: persisted returns true in case change is
    #       NOT caused by adding or removing record to DB
    if folder_name_changed? && persisted?
      errors.add(:folder_name,
                 'was changed. You cannot change folder_name of already created instance.')
    end
  end
end
