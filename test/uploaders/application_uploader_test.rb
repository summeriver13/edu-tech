require "test_helper"

class ApplicationUploaderTest < ActiveSupport::TestCase
  FakeFile = Struct.new(:public_url, :signed_url) do
    def url(*)
      signed_url
    end
  end

  test "marks covers and videos as public assets" do
    assert CoverUploader.new.public_asset?
    assert ResourceUploader.new.public_asset?
    refute SubmissionUploader.new.public_asset?
  end

  test "uses the public url for a public asset" do
    uploader = CoverUploader.new
    uploader.define_singleton_method(:file) do
      FakeFile.new("https://cdn.example/cover.png", "https://signed.example/cover.png")
    end

    assert_equal "https://cdn.example/cover.png", uploader.url
  end

  test "uses the signed url for a submission" do
    uploader = SubmissionUploader.new
    uploader.define_singleton_method(:file) do
      FakeFile.new("https://cdn.example/answer.pdf", "https://signed.example/answer.pdf")
    end

    assert_equal "https://signed.example/answer.pdf", uploader.url
  end
end
