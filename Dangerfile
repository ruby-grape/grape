# Sometimes it's a README fix, or something like that - which isn't relevant for
# including in a project's CHANGELOG for example
declared_trivial = github.pr_title.include? "#trivial"

# Has any changes happened inside the lib dir?
has_app_changes = !git.modified_files.grep(/lib/).empty?
if git.modified_files.include?("CHANGELOG.md") == false && !declared_trivial
  fail("No CHANGELOG changes made in CHANGELOG.md when there are library changes.", sticky: false)
    pr_number = github.pr_json["number"] 
    markdown <<-MARKDOWN
Here's an example of your CHANGELOG entry:

```markdown
* [##{pr_number}](https://github.com/ruby-grape/grape/pull/#{pr_number}): #{github.pr_title} [@#{github.pr_author}](https://github.com/#{github.pr_author}).
```
MARKDOWN
end

# Don't let testing shortcuts get into master by accident, 
# ensuring that we don't get green builds based on a subset of tests
(git.modified_files + git.added_files - %w(Dangerfile)).each do |file|
  next unless File.file?(file)
  contents = File.read(file)
  if file.start_with?('spec')
    fail("`xit` or `fit` left in tests (#{file})") if contents =~ /^\w*[xf]it/
    fail("`fdescribe` left in tests (#{file})") if contents =~ /^\w*fdescribe/
  end
end