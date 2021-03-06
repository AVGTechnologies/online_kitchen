# == Schema Information
#
# Table name: users
#
#  id         :integer          not null, primary key
#  name       :string           default(""), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

# User representation
class User < ActiveRecord::Base
  has_many :configurations, dependent: :destroy, inverse_of: :user

  validates :name,
            presence: true,
            length: { minimum: 1 },
            uniqueness: { scope: :id },
            format: {
              with: /\A[[[:alnum:]]._\-\\]+\z/,
              message: 'allows letters, dots, underscores, dashes and numbers'
            }

  strip_attributes

  def destroy
    destroyable? ? super : self
  end

  private

  def destroyable?
    return true if configurations.where(deleted: false).count.zero?

    errors.add(:base, 'Cannot delete user with running configuration')
    false
  end
end
