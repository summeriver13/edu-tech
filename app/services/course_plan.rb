class CoursePlan
  Change = Data.define(:action, :text)

  def initialize(course, repo_dir)
    @course = course
    @repo_dir = repo_dir
  end

  def changes(manifest)
    list = []
    list << compare(nil, "课程信息", @course, (manifest["course"] || {}).slice("title", "description", "credit"))
    list.concat(term_changes(manifest["term"] || {}))
    list.concat(resource_changes(Array(manifest["resources"])))
    list.concat(activity_changes(Array(manifest["activities"])))
    list.concat(assessment_changes(Array(manifest["assessments"])))
    list.concat(lesson_changes(Array(manifest["lessons"])))
    declared_lessons = Array(manifest["lessons"]).map { |item| item["path"] }
    list.concat(question_changes(Array(manifest["questions"]), declared_lessons))
    list.compact
  end

  private

  def term_changes(term)
    attributes = {}
    attributes["week1_start"] = term["week1_start"] if term["week1_start"]
    attributes["time_zone"] = term["time_zone"] if term["time_zone"]
    attributes["term_weeks"] = term["weeks"] if term["weeks"]
    late_penalty = term["late_penalty"] || {}
    attributes["late_penalty_percent"] = late_penalty["percent_per_day"] if late_penalty["percent_per_day"]
    attributes["late_penalty_max_days"] = late_penalty["max_days"] if late_penalty["max_days"]
    attributes["census_at"] = term["census_at"] if term["census_at"]
    attributes["min_attendance"] = term["min_attendance"] if term["min_attendance"]
    return [] if attributes.empty?

    [ compare(nil, "学期设置", @course, attributes) ].compact
  end

  def resource_changes(items)
    items.filter_map do |item|
      record = @course.resources.find_by(name: item["name"])
      attributes = {
        "resource_type" => item["type"], "url" => item["url"], "description" => item["description"]
      }
      compare("资源", item["name"], record, attributes)
    end
  end

  def activity_changes(items)
    items.filter_map do |item|
      record = @course.activities.find_by(activity_type: item["type"], start_time: item["start"])
      attributes = { "end_time" => item["end"], "location" => item["location"], "description" => item["description"] }
      compare("活动", "#{item["type"]} #{item["start"]}", record, attributes)
    end
  end

  def assessment_changes(items)
    items.flat_map do |item|
      key = item["key"]
      raise CourseRepo::Error, "评估项缺少 key。" if key.blank?

      record = @course.assessments.find_by(key: key)
      changes = [ compare("评估", key, record, assessment_attributes(item)) ]
      changes.concat(deliverable_changes(record, item, key))
      changes
    end.compact
  end

  def deliverable_changes(record, item, key)
    Array(item["deliverables"]).filter_map do |deliverable|
      name = deliverable["name"]
      raise CourseRepo::Error, "交付物缺少 name。" if name.blank?

      existing = record&.deliverables&.find_by(name: name)
      compare("交付物", "#{key} / #{name}", existing, { "due_at" => deliverable["due_at"] })
    end
  end

  def lesson_changes(items)
    items.each_with_index.filter_map do |item, index|
      path = item["path"]
      raise CourseRepo::Error, "课时缺少 path。" if path.blank?

      body = RepoFile.read(@repo_dir, path)
      record = @course.lessons.find_by(source_path: path)
      attributes = {
        "position" => index + 1,
        "title" => item["title"].presence || lesson_title(body, path),
        "body" => body,
        "body_html" => MarkdownRenderer.render(body)
      }
      compare("课时", path, record, attributes)
    end
  end

  def question_changes(items, declared_lessons)
    items.filter_map do |item|
      key = item["key"]
      raise CourseRepo::Error, "题目缺少 key。" if key.blank?

      lesson_path = item["lesson"].presence
      check_lesson_path(lesson_path, declared_lessons)
      record = @course.questions.find_by(key: key)
      next Change.new("新增", "题目 #{key}") if record.nil?

      attributes = question_attributes(item)
      changed = attributes.keys.reject { | field | same?(record, field, attributes[field]) }
      changed << "lesson" if record.lesson&.source_path != lesson_path
      next if changed.empty?

      Change.new("更新", "题目 #{key}（#{changed.join("、")}）")
    end
  end

  def question_attributes(item)
    {
      "kind" => item["kind"].presence || "single",
      "stem" => item["stem"],
      "choices" => Array(item["choices"]).map(&:to_s),
      "answer" => item["answer"],
      "explanation" => item["explanation"],
      "topic" => item["topic"],
      "slo" => item["slo"],
      "source" => item["source"]
    }
  end

  def check_lesson_path(path, declared_lessons)
    return if path.blank?
    return if @course.lessons.exists?(source_path: path)
    return if declared_lessons.include?(path)

    raise CourseRepo::Error, "题目引用的课时不存在：#{path}。"
  end

  def assessment_attributes(item)
    {
      "title" => item["title"].presence || item["key"],
      "kind" => item["kind"].presence || "assignment",
      "weight" => item["weight"].to_f,
      "group_work" => item["group_work"] || false,
      "hurdle" => item["hurdle"] || false,
      "min_score" => item["min_score"],
      "pass_fail" => item["pass_fail"] || false,
      "sittings" => item["sittings"],
      "best_of" => item["best_of"],
      "word_limit" => item["word_limit"],
      "word_limit_tolerance" => item["word_limit_tolerance"] || 10,
      "group_min" => item["group_min"],
      "group_max" => item["group_max"],
      "ai_policy" => item["ai_policy"],
      "slos" => Array(item["slos"]).map(&:to_s),
      "scope" => item["scope"],
      "venue" => item["venue"],
      "opens_at" => item["opens_at"],
      "due_at" => item["due_at"],
      "description" => item["description"]
    }
  end

  def lesson_title(body, path)
    heading = body.each_line.find { |line| line.start_with?("# ") }
    heading ? heading.delete_prefix("# ").strip : File.basename(path, ".*")
  end

  def compare(section, label, record, attributes)
    text = [ section, label ].compact.join(" ")
    return Change.new("新增", text) if record.nil?

    changed = attributes.keys.reject { |key| same?(record, key, attributes[key]) }
    return nil if changed.empty?

    Change.new("更新", "#{text}（#{changed.join("、")}）")
  end

  def same?(record, key, value)
    current = record.public_send(key)
    case value
    when Array then current.to_a.map(&:to_s) == value.map(&:to_s)
    when Numeric then current.is_a?(Numeric) && current.to_f == value.to_f
    when Time then current.present? && current.to_i == value.to_i
    when Date then current == value
    else current.to_s == value.to_s
    end
  end
end
