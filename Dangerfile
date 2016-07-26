# Has any changes happened inside the lib dir?
has_app_changes = !git.modified_files.grep(/lib/).empty?

if git.modified_files.include?('CHANGELOG.md') == false && has_app_changes
  pr_number = github.pr_json['number']
  markdown <<-MARKDOWN
Here's an example of your CHANGELOG entry:

```markdown
* [##{pr_number}](https://github.com/ruby-grape/grape/pull/#{pr_number}): #{github.pr_title} - [@#{github.pr_author}](https://github.com/#{github.pr_author}).
```
  fail('No CHANGELOG changes made in CHANGELOG.md when there are library changes.', sticky: false)
MARKDOWN
end

# Don't let testing shortcuts get into master by accident,
# ensuring that we don't get green builds based on a subset of tests.
(git.modified_files + git.added_files - %w(Dangerfile)).each do |file|
  next unless File.file?(file)
  contents = File.read(file)
  if file.start_with?('spec')
    raise("`xit` or `fit` left in tests (#{file})") if contents =~ /^\w*[xf]it/
    raise("`fdescribe` left in tests (#{file})") if contents =~ /^\w*fdescribe/
  end
end
