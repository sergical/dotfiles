#!/usr/bin/env ruby
# frozen_string_literal: true

# Skills we do not own and cannot mark at source. Everything else is derived
# from `disable-model-invocation: true` in the skill's own frontmatter.
EXTERNAL_USER_INVOKED_SKILLS = %w[
  cmux-diagnostics
  code-review
  tdd
  wizard
].freeze

DISABLE_MODEL_INVOCATION = "disable-model-invocation: true"

check_only = ARGV.delete("--check")
skills_root = ARGV.fetch(0)

def read_document(skill_path)
  lines = File.readlines(skill_path)
  frontmatter_end = lines.each_index.drop(1).find { |index| lines[index].strip == "---" }
  abort "Invalid frontmatter: #{skill_path}" unless lines.first&.strip == "---" && frontmatter_end
  [lines, frontmatter_end]
end

documents = []

Dir.glob(File.join(skills_root, "*", "SKILL.md")).sort.each do |skill_path|
  skill_id = File.basename(File.dirname(skill_path))
  lines, frontmatter_end = read_document(skill_path)
  frontmatter = lines[1...frontmatter_end].map(&:strip)

  model_invoked = !frontmatter.include?(DISABLE_MODEL_INVOCATION)
  external = EXTERNAL_USER_INVOKED_SKILLS.include?(skill_id)
  next if model_invoked && !external

  documents << [skill_path, lines, frontmatter_end, model_invoked]
end

abort "No user-only skills found under #{skills_root}" if documents.empty?

if check_only
  documents.each do |skill_path, lines, frontmatter_end, _model_invoked|
    frontmatter = lines[1...frontmatter_end].map(&:strip)
    unless frontmatter.include?(DISABLE_MODEL_INVOCATION)
      abort "Missing disable-model-invocation: #{skill_path}"
    end
    unless frontmatter.include?("opencode/autoinvoke: false") && frontmatter.include?("opencode/slash: true")
      abort "Incorrect OpenCode user-only metadata: #{skill_path}"
    end
  end

  missing = EXTERNAL_USER_INVOKED_SKILLS.reject { |id| File.file?(File.join(skills_root, id, "SKILL.md")) }
  warn "Skipped absent external user-only skills: #{missing.join(", ")}" unless missing.empty?
  exit
end

documents.each do |skill_path, lines, frontmatter_end, model_invoked|
  lines.insert(frontmatter_end, "#{DISABLE_MODEL_INVOCATION}\n") if model_invoked
  frontmatter_end += 1 if model_invoked

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
