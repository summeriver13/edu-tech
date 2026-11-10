class RepoFile
  def self.read(root, relative)
    File.read(path(root, relative))
  end

  def self.path(root, relative)
    base = Pathname(root).expand_path
    file = base.join(relative).expand_path
    raise CourseRepo::Error, "课时路径越界：#{relative}。" unless file.to_s.start_with?(base.to_s + File::SEPARATOR)
    raise CourseRepo::Error, "课时文件不存在：#{relative}。" unless file.file?

    file
  end
end
