#!/usr/bin/env ruby
# frozen_string_literal: true

USER_INVOKED_SKILLS = %w[
  ask-matt
  grill-me
  grill-with-docs
  handoff
  implement
  improve-codebase-architecture
  setup-matt-pocock-skills
  teach
  to-questionnaire
  to-spec
  to-tickets
  triage
  wait-what
  wayfinder
].freeze

check_only = ARGV.delete("--check")
skills_root = ARGV.fetch(0)
documents = []

USER_INVOKED_SKILLS.each do |skill_id|
  skill_path = File.join(skills_root, skill_id, "SKILL.md")
  abort "Missing expected user-only skill: #{skill_path}" unless File.file?(skill_path)

  lines = File.readlines(skill_path)
  frontmatter_end = lines.each_index.drop(1).find { |index| lines[index].strip == "---" }
  abort "Invalid frontmatter: #{skill_path}" unless lines.first&.strip == "---" && frontmatter_end

  frontmatter = lines[1...frontmatter_end]
  unless frontmatter.any? { |line| line.strip == "disable-model-invocation: true" }
    abort "Refusing to change model-invoked skill: #{skill_path}"
  end

  documents << [skill_path, lines, frontmatter_end]
end

if check_only
  documents.each do |skill_path, lines, frontmatter_end|
    frontmatter = lines[1...frontmatter_end].map(&:strip)
    unless frontmatter.include?("opencode/autoinvoke: false") && frontmatter.include?("opencode/slash: true")
      abort "Incorrect OpenCode user-only metadata: #{skill_path}"
    end
  end
  exit
end

documents.each do |skill_path, lines, frontmatter_end|
  frontmatter_range = 1...frontmatter_end
  autoinvoke_index = frontmatter_range.find { |index| lines[index].strip.start_with?("opencode/autoinvoke:") }
  slash_index = frontmatter_range.find { |index| lines[index].strip.start_with?("opencode/slash:") }

  lines[autoinvoke_index] = "  opencode/autoinvoke: false\n" if autoinvoke_index
  lines[slash_index] = "  opencode/slash: true\n" if slash_index

  metadata_index = frontmatter_range.find { |index| lines[index] == "metadata:\n" }
  additions = []
  additions << "  opencode/autoinvoke: false\n" unless autoinvoke_index
  additions << "  opencode/slash: true\n" unless slash_index

  if metadata_index
    lines.insert(metadata_index + 1, *additions)
  else
    lines.insert(frontmatter_end, "metadata:\n", *additions)
  end

  temporary_path = "#{skill_path}.tmp"
  File.write(temporary_path, lines.join)
  File.chmod(File.stat(skill_path).mode, temporary_path)
  File.rename(temporary_path, skill_path)
end
