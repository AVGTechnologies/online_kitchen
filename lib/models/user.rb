class User < ActiveRecord::Base
  has_many :configurations, dependent: :destroy, inverse_of: :user

  validates :name,
    presence: true,
    length: {minimum: 5},
    uniqueness: { scope: :id },
    format: {
      with: /\A[A-Za-z0-9_\.\\]+\z/,
      message: "allows letters, dots, underscores and numbers"
    }

    strip_attributes

    def destroy
      destroyable? ? super : self
    end

    private

      def destroyable?
        return true if configurations.where(deleted: false).count == 0
        errors.add(:base, "Cannot delete user with running configuratin")
        false
      end
end
