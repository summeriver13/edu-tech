# 数据表

## course 课程表

```ruby
class Course < ApplicationRecord
  has_many :course_resources, class_name: 'CourseResource'
  has_many :course_activities, class_name: 'CourseActivity'

  validates :title, presence: true
  validates :description, presence: true
  validates :credit, presence: true, numericality: { greater_than_or_equal_to: 0 }

  scope :active, -> { where(active: true) }
end
```

### activity 活动表


### resource 资源表

## User 用户表
