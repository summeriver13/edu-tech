ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers.
    # fork() is unimplemented on Windows, so run serially there.
    parallelize(workers: :number_of_processors) unless Gem.win_platform?

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
    def git_init(dir)
      File.write(File.join(dir, ".keep"), "")
      system("git", "-C", dir, "init", "--quiet", exception: true)
      system("git", "-C", dir, "add", ".", exception: true)
      system("git", "-C", dir, "-c", "user.email=test@example.com", "-c", "user.name=Test", "commit", "--quiet", "-m", "init", exception: true)
    end
  end
end

class ActionDispatch::IntegrationTest
  def log_in_as(user, password: "secret")
    post session_path, params: { name: user.name, password: password }
  end
end
