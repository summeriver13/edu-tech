class Course < ApplicationRecord
  has_many :resources, dependent: :destroy
  has_many :activities, dependent: :destroy
end
