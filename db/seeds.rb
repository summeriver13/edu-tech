admin = User.find_or_initialize_by(name: "admin")
admin.update!(password: "secret", password_confirmation: "secret", role: "admin")

member = User.find_or_initialize_by(name: "member")
member.update!(password: "secret", password_confirmation: "secret", role: "member")

seed_courses = [
  {
    course_number: "CS101",
    title: "程序设计入门",
    description: "从变量、控制流到函数，用 Ruby 建立编程基础。",
    image_url: "https://placehold.co/600x400",
    credit: 3.0,
    resources: [
      { name: "第 1 讲 环境搭建", resource_type: "video", url: "https://example.com/cs101/lecture-1" },
      { name: "课程大纲", resource_type: "document", url: "https://example.com/cs101/syllabus.pdf" }
    ],
    activities: [
      { activity_type: "lecture", start_time: Time.zone.parse("2026-11-10 09:00"), end_time: Time.zone.parse("2026-11-10 10:30"), location: "教三 201" }
    ]
  },
  {
    course_number: "CS201",
    title: "Web 开发实践",
    description: "用 Rails 完成课程管理系统的需求分析、开发与部署。",
    image_url: "https://placehold.co/600x401",
    credit: 4.0,
    resources: [
      { name: "Rails 指南", resource_type: "link", url: "https://guides.rubyonrails.org" }
    ],
    activities: [
      { activity_type: "lab", start_time: Time.zone.parse("2026-11-12 14:00"), end_time: Time.zone.parse("2026-11-12 16:00"), location: "机房 305" }
    ]
  },
  {
    course_number: "CS301",
    title: "数据库系统",
    description: "关系模型、SQL 与事务，理解数据在系统中的位置。",
    image_url: "https://placehold.co/600x402",
    credit: 3.0,
    resources: [
      { name: "实验手册", resource_type: "document", url: "https://example.com/cs301/lab.pdf" }
    ],
    activities: [
      { activity_type: "exam", start_time: Time.zone.parse("2026-11-20 09:00"), end_time: Time.zone.parse("2026-11-20 11:00"), location: "教二 108" }
    ]
  }
]

seed_courses.each do |attributes|
  course = Course.find_or_initialize_by(course_number: attributes[:course_number])
  course.update!(attributes.except(:resources, :activities))

  attributes[:resources].each do |resource_attributes|
    course.resources.find_or_initialize_by(name: resource_attributes[:name]).update!(resource_attributes)
  end

  attributes[:activities].each do |activity_attributes|
    scope = { activity_type: activity_attributes[:activity_type], start_time: activity_attributes[:start_time] }
    course.activities.find_or_initialize_by(scope).update!(activity_attributes)
  end
end

puts "Seeded #{Course.count} courses, #{Resource.count} resources, #{Activity.count} activities, #{User.count} users."
