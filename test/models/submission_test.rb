require "test_helper"

class SubmissionTest < ActiveSupport::TestCase
  test "requires body or file" do
    submission = Submission.new(assessment: assessments(:one), user: users(:one))
    assert_not submission.valid?
    assert_includes submission.errors[:base], "请填写内容或上传附件"
  end

  test "is valid with a body" do
    submission = Submission.new(assessment: assessments(:one), user: users(:one), body: "我的答案")
    assert submission.valid?
  end

  test "allows one submission per assessment and user" do
    Submission.create!(assessment: assessments(:one), user: users(:one), body: "第一次")
    duplicate = Submission.new(assessment: assessments(:one), user: users(:one), body: "第二次")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:base], "已经提交过了。"
  end
end
