# --------------------------------------------------------------------------------------------------------------------
# Has any changes happened inside the actual library code?
# --------------------------------------------------------------------------------------------------------------------
has_app_changes = !git.modified_files.grep(/lib/).empty?
has_spec_changes = !git.modified_files.grep(/spec/).empty?

# --------------------------------------------------------------------------------------------------------------------
# You've made changes to lib, but didn't write any tests?
# --------------------------------------------------------------------------------------------------------------------
if has_app_changes && !has_spec_changes
  raise("There're library changes, but not tests. That's OK as long as you're refactoring existing code.", sticky: false)
end

# --------------------------------------------------------------------------------------------------------------------
# You've made changes to specs, but no library code has changed?
# --------------------------------------------------------------------------------------------------------------------
if !has_app_changes && has_spec_changes
  message('We really appreciate pull requests that demonstrate issues, even without a fix. That said, the next step is to try and fix the failing tests!', sticky: false)
end

# --------------------------------------------------------------------------------------------------------------------
# Have you updated CHANGELOG.md?
# --------------------------------------------------------------------------------------------------------------------
if !git.modified_files.include?('CHANGELOG.md') && has_app_changes
  pr_number = github.pr_json['number']
  markdown <<-MARKDOWN
Here's an example of a CHANGELOG.md entry:

```markdown
* [##{pr_number}](https://github.com/ruby-grape/grape/pull/#{pr_number}): #{github.pr_title} - [@#{github.pr_author}](https://github.com/#{github.pr_author}).
```
MARKDOWN
  raise('Please update CHANGELOG.md.', sticky: false)
end

# --------------------------------------------------------------------------------------------------------------------
# Is the CHANGELOG.md format correct?
# --------------------------------------------------------------------------------------------------------------------

your_contribution_here = false
releases = 0
errors = 0
File.open('CHANGELOG.md').each_line do |line|
  # only look at the top releases, we entered a lot of changes without a PR before
  if line == "==================\n"
    releases += 1
    break if releases == 5
  end
  # ignore lines that aren't changes
  next unless line[0] == '*'
  # notice your contribution here
  if line == "* Your contribution here.\n"
    your_contribution_here = true
    next
  end
  # match the PR format
  next if line =~ %r{^\*\s\[\#\d+\]\(https:\/\/github\.com\/.*\d+\)\: [\`[:upper:]].* \- \[\@[\w\d\-\_]+\]\(https:\/\/github\.com\/.*[\w\d\-\_]+\)\.$}
  errors += 1
  markdown <<-MARKDOWN
```markdown
#{line}```
  MARKDOWN
end

raise("One of the lines below found in CHANGELOG.md doesn't match the expected format. Please make it look like the other lines, pay attention to periods and spaces.", sticky: false) if errors > 0
raise('Please put back the `* Your contribution here.` line into CHANGELOG.md.', sticky: false) unless your_contribution_here

# --------------------------------------------------------------------------------------------------------------------
# Don't let testing shortcuts get into master by accident,
# ensuring that we don't get green builds based on a subset of tests.
# --------------------------------------------------------------------------------------------------------------------

(git.modified_files + git.added_files - %w(Dangerfile)).each do |file|
  next unless File.file?(file)
  contents = File.read(file)
  if file.start_with?('spec')
    raise("`xit` or `fit` left in tests (#{file})") if contents =~ /^\w*[xf]it/
    raise("`fdescribe` left in tests (#{file})") if contents =~ /^\w*fdescribe/
  end
end
