# == Schema Information
#
# Table name: machines
#
#  id                  :integer          not null, primary key
#  name                :string
#  template            :string
#  environment         :text
#  configuration_id_id :integer
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#

class Machine < ActiveRecord::Base
  belongs_to :configuration, inverse_of: :machines

  validates :name,
    presence: true,
    length: {minimum: 3},
    uniqueness: { scope: :configuration_id },
    format: {
      with: /\A[A-Za-z0-9_\.]+\z/,
      message: "only allows letters, digits, underscore and dots"
    }

  validates :template,
    presence: true,
    length: {minimum: 3}, # TODO: Validate format cluster.name
    format: {
      with: /\A[A-Za-z]{1,10}\.[A-Za-z0-9_]+\z/,
      message: "cluster and name separated by dot, letters only"
    }

  validates :state, inclusion: { in: %w(queued ready destroy_queued) }
  validate :environment_has_allowed_structure
  serialize :environment, JSON

  strip_attributes :except => :environment

  delegate :user, :folder_name, to: :configuration

  def job_id
   "%d.%d" % [configuration.id, id]
  end

  private
    def environment_has_allowed_structure
      return if self.environment.nil?

      unless Hash === environment
        errors.add(:environment, "has to be Hash (key-value) like structure")
        return false
      end

      environment.each do |key, value|
        unless key =~ /\A[A-Za-z][A-Za-z0-9_]*\z/
          errors.add(:environment, "keys has to be Literal (e.g. start on letter followed by letter, digits or underscore)")
          return false
        end
        unless String === value
          errors.add(:environment, "value has to be String")
          return false
        end
      end
      true
    end
end
