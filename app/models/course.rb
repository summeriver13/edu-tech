class Course < ApplicationRecord
  has_many :resources
  has_many :activities
end
