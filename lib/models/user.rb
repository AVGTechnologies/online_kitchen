class User < ActiveRecord::Base
  has_many :configuration, inverse_of: :user

  validates :name,
    presence: true,
    length: {minimum: 7},
    uniqueness: { scope: :id },
    format: {
      with: /\A[A-Za-z0-9_\.\\]+\z/,
      message: "allows letters, dots, underscores and numbers"
    }

    strip_attributes
end
