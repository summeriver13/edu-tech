require "open3"
require "yaml"

class CourseRepo
  class Error < StandardError; end

  MANIFEST = "course.yml".freeze
  WEIGHT_TOTAL = 100
  def self.repo_root
    base = Rails.env.test? ? Rails.root.join("tmp", "repos") : Rails.root.join("storage", "repos")
    Rails.env.test? ? base.join(Process.pid.to_s) : base
  end

  Result = Data.define(:success, :message) do
    def success?
      success
    end
  end

  Preview = Data.define(:success, :message, :changes) do
    def success?
      success
    end
  end

  def initialize(course)
    @course = course
  end

  def preview
    return Preview.new(success: false, message: "课程未配置仓库地址。", changes: []) if @course.repo_url.blank?

    checkout
    changes = CoursePlan.new(@course, repo_dir).changes(load_manifest)
    Preview.new(success: true, message: "已读取 #{current_sha.first(7)}。", changes: changes)
  rescue Error, Psych::SyntaxError => error
    Preview.new(success: false, message: "预览失败：#{error.message}", changes: [])
  end

  def sync
    return failure("课程未配置仓库地址。") if @course.repo_url.blank?

    checkout
    apply!(load_manifest)
    Result.new(success: true, message: "已同步到 #{@course.commit_sha.first(7)}。")
  rescue Error, Psych::SyntaxError, ActiveRecord::RecordInvalid => error
    failure("同步失败：#{error.message}")
  end

  private

  def failure(message)
    Result.new(success: false, message: message)
  end

  def repo_dir
    self.class.repo_root.join(@course.course_number.to_s.gsub(/[^\w-]/, "_"))
  end

  def checkout
    FileUtils.mkdir_p(self.class.repo_root)
    if Dir.exist?(repo_dir.join(".git")) && remote_url == @course.repo_url
      run!("git", "-C", repo_dir.to_s, "fetch", "--depth", "1", "--quiet", "origin")
      run!("git", "-C", repo_dir.to_s, "reset", "--hard", "--quiet", "FETCH_HEAD")
    else
      FileUtils.rm_rf(repo_dir)
      run!("git", "clone", "--depth", "1", "--quiet", @course.repo_url, repo_dir.to_s)
    end
  end

  def remote_url
    run!("git", "-C", repo_dir.to_s, "remote", "get-url", "origin").strip
  rescue Error
    nil
  end

  def load_manifest
    path = repo_dir.join(MANIFEST)
    raise Error, "仓库缺少 #{MANIFEST}。" unless File.exist?(path)

    YAML.safe_load_file(path, permitted_classes: [ Date, Time ], aliases: true) || {}
  end

  def apply!(manifest)
    assessments = manifest["assessments"] || []
    check_weight_total!(assessments)

    ActiveRecord::Base.transaction do
      update_course(manifest["course"] || {})
      sync_term(manifest["term"] || {})
      sync_resources(manifest["resources"] || [])
      sync_activities(manifest["activities"] || [])
      sync_lessons(manifest["lessons"] || [])
      sync_assessments(assessments)
      sync_questions(manifest["questions"] || [])
      @course.update!(commit_sha: current_sha, synced_at: Time.current)
    end
  end

  def check_weight_total!(items)
    return if items.empty?

    total = items.sum { |item| item["weight"].to_f }
    return if (total - WEIGHT_TOTAL).abs < 0.001

    raise Error, "评估项权重合计必须为 #{WEIGHT_TOTAL}，当前为 #{total}。"
  end

  def sync_lessons(items)
    items.each_with_index do |item, index|
      path = item["path"]
      raise Error, "课时缺少 path。" if path.blank?

      body = RepoFile.read(repo_dir, path)
      lesson = @course.lessons.find_or_initialize_by(source_path: path)
      lesson.position = index + 1
      lesson.title = item["title"].presence || lesson_title(body, path)
      lesson.body = body
      lesson.save!
    end
  end

  def lesson_title(body, path)
    heading = body.each_line.find { |line| line.start_with?("# ") }
    heading ? heading.delete_prefix("# ").strip : File.basename(path, ".*")
  end

  def sync_assessments(items)
    items.each do |item|
      key = item["key"]
      raise Error, "评估项缺少 key。" if key.blank?

      assessment = @course.assessments.find_or_initialize_by(key: key)
      assessment.assign_attributes(
        title: item["title"].presence || key,
        kind: item["kind"].presence || "assignment",
        weight: item["weight"].to_f,
        group_work: item["group_work"] || false,
        hurdle: item["hurdle"] || false,
        min_score: item["min_score"],
        pass_fail: item["pass_fail"] || false,
        sittings: item["sittings"],
        best_of: item["best_of"],
        word_limit: item["word_limit"],
        word_limit_tolerance: item["word_limit_tolerance"] || 10,
        group_min: item["group_min"],
        group_max: item["group_max"],
        ai_policy: item["ai_policy"],
        slos: Array(item["slos"]).map(&:to_s),
        scope: item["scope"],
        venue: item["venue"],
        opens_at: item["opens_at"],
        due_at: item["due_at"],
        description: item["description"]
      )
      assessment.save!
      sync_deliverables(assessment, item["deliverables"])
    end
  end

  def sync_questions(items)
    items.each do |item|
      key = item["key"]
      raise Error, "题目缺少 key。" if key.blank?

      question = @course.questions.find_or_initialize_by(key: key)
      question.assign_attributes(
        kind: item["kind"].presence || "single",
        stem: item["stem"],
        choices: Array(item["choices"]).map(&:to_s),
        answer: item["answer"],
        explanation: item["explanation"],
        topic: item["topic"],
        slo: item["slo"],
        source: item["source"],
        lesson: lesson_by_path(item["lesson"])
      )
      question.save!
    end
  end

  def lesson_by_path(path)
    return nil if path.blank?

    @course.lessons.find_by(source_path: path) || raise(Error, "题目引用的课时不存在：#{path}。")
  end

  def sync_deliverables(assessment, items)
    Array(items).each do |item|
      name = item["name"]
      raise Error, "交付物缺少 name。" if name.blank?

      deliverable = assessment.deliverables.find_or_initialize_by(name: name)
      deliverable.due_at = item["due_at"]
      deliverable.save!
    end
  end

  def sync_term(term)
    return if term.blank?

    late_penalty = term["late_penalty"] || {}
    @course.assign_attributes(
      week1_start: term["week1_start"] || @course.week1_start,
      time_zone: term["time_zone"].presence || @course.time_zone,
      term_weeks: term["weeks"] || @course.term_weeks,
      late_penalty_percent: late_penalty["percent_per_day"] || @course.late_penalty_percent,
      late_penalty_max_days: late_penalty["max_days"] || @course.late_penalty_max_days,
      census_at: term["census_at"] || @course.census_at,
      min_attendance: term["min_attendance"] || @course.min_attendance
    )
    @course.save!
  end

  def update_course(attributes)
    allowed = attributes.slice("title", "description", "credit")
    @course.update!(allowed) if allowed.any?
  end

  def sync_resources(items)
    items.each do |item|
      resource = @course.resources.find_or_initialize_by(name: item.fetch("name"))
      resource.assign_attributes(resource_type: item["type"], url: item["url"], description: item["description"])
      resource.save!
    end
  end

  def sync_activities(items)
    items.each do |item|
      activity = @course.activities.find_or_initialize_by(activity_type: item.fetch("type"), start_time: item.fetch("start"))
      activity.assign_attributes(end_time: item["end"], location: item["location"], description: item["description"])
      activity.save!
    end
  end

  def current_sha
    run!("git", "-C", repo_dir.to_s, "rev-parse", "HEAD").strip
  end

  def run!(*command)
    stdout, stderr, status = Open3.capture3(*command)
    raise Error, (stderr.strip.empty? ? command.join(" ") : stderr.strip) unless status.success?

    stdout
  rescue Errno::ENOENT
    raise Error, "找不到 git 命令。"
  end
end
