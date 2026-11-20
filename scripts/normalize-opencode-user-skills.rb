#!/usr/bin/env ruby
# frozen_string_literal: true

# Skills we do not own and cannot mark at source. Everything else is derived
# from `disable-model-invocation: true` in the skill's own frontmatter.
# Codex ignores that field. It hides a skill from the model only when
# agents/openai.yaml sets `policy.allow_implicit_invocation: false`, so this
# script writes that file for every user-only skill too.
EXTERNAL_USER_INVOKED_SKILLS = %w[
  cmux-diagnostics
  code-review
  matt-tdd
  matt-wizard
].freeze

DISABLE_MODEL_INVOCATION = "disable-model-invocation: true"

check_only = ARGV.delete("--check")
skills_root = ARGV.fetch(0)

def read_document(skill_path)
  lines = File.readlines(skill_path)
  frontmatter_end = lines.each_index.drop(1).find { |index| lines[index].strip == "---" }
  abort "Invalid frontmatter: #{skill_path}" unless lines.first&.strip == "---" && frontmatter_end
  keys = lines[1...frontmatter_end].map { |line| line[/\A([A-Za-z][\w-]*):/, 1] }.compact
  repeated = keys.group_by(&:itself).select { |_key, copies| copies.size > 1 }.keys
  # Codex parses frontmatter strictly and skips a skill whose keys repeat.
  abort "Repeated frontmatter key #{repeated.join(", ")}: #{skill_path}" unless repeated.empty?
  [lines, frontmatter_end]
end

CODEX_POLICY_LINE = "  allow_implicit_invocation: false\n"

def codex_policy_path(skill_path)
  File.join(File.dirname(skill_path), "agents", "openai.yaml")
end

def codex_policy_set?(skill_path)
  path = codex_policy_path(skill_path)
  File.file?(path) && File.read(path).match?(/^policy:\n(?:[ \t]+.*\n)*?[ \t]+allow_implicit_invocation: false[ \t]*$/)
end

def write_codex_policy(skill_path)
  return if codex_policy_set?(skill_path)

  path = codex_policy_path(skill_path)
  lines = File.file?(path) ? File.readlines(path) : []
  lines[-1] += "\n" if lines.any? && !lines[-1].end_with?("\n")
  setting_index = lines.index { |line| line.match?(/\A[ \t]+allow_implicit_invocation:/) }
  policy_index = lines.index { |line| line.rstrip == "policy:" }
  if setting_index
    lines[setting_index] = CODEX_POLICY_LINE
  elsif policy_index
    lines.insert(policy_index + 1, CODEX_POLICY_LINE)
  else
    lines.push("policy:\n", CODEX_POLICY_LINE)
  end
  Dir.mkdir(File.dirname(path)) unless File.directory?(File.dirname(path))
  File.write(path, lines.join)
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
    abort "Missing Codex policy in agents/openai.yaml: #{skill_path}" unless codex_policy_set?(skill_path)
  end

  missing = EXTERNAL_USER_INVOKED_SKILLS.reject { |id| File.file?(File.join(skills_root, id, "SKILL.md")) }
  warn "Skipped absent external user-only skills: #{missing.join(", ")}" unless missing.empty?
  exit
end

documents.each do |skill_path, lines, frontmatter_end, model_invoked|
  write_codex_policy(skill_path)
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
