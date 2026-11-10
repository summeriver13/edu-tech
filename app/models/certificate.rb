class Certificate < ApplicationRecord
  SERIAL_LENGTH = 8

  belongs_to :course
  belongs_to :user

  validates :serial, presence: true, uniqueness: true
  validates :issued_at, presence: true
  validates :user_id, uniqueness: { scope: :course_id }

  before_validation -> { self.issued_at ||= Time.current }
  before_validation -> { self.serial ||= next_serial }

  def self.issue_for(user, course)
    return nil unless course.certificate_ready?(user)
    return course.certificates.find_by(user: user) if course.certificates.exists?(user: user)

    course.certificates.create!(user: user)
  end

  private

  def next_serial
    loop do
      serial = "#{course.course_number}-#{SecureRandom.alphanumeric(SERIAL_LENGTH).upcase}"
      break serial unless Certificate.exists?(serial: serial)
    end
  end
end
