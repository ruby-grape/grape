const fs = require('fs');
const core = require('@actions/core');

module.exports = async ({ github, context }) => {
  const hasItems = (arr) => Array.isArray(arr) && arr.length > 0;

  let report;
  try {
    report = JSON.parse(fs.readFileSync('danger_report.json', 'utf8'));
  } catch (e) {
    console.log('No danger report found, skipping comment');
    return;
  }

  if (!report.pr_number) {
    console.log('No PR number found in report, skipping comment');
    return;
  }

  let body = '## Danger Report\n\n';

  if (hasItems(report.errors)) {
    body += '### ❌ Errors\n';
    report.errors.forEach(e => body += `- ${e}\n`);
    body += '\n';
  }

  if (hasItems(report.warnings)) {
    body += '### ⚠️ Warnings\n';
    report.warnings.forEach(w => body += `- ${w}\n`);
    body += '\n';
  }

  if (hasItems(report.messages)) {
    body += '### ℹ️ Messages\n';
    report.messages.forEach(m => body += `- ${m}\n`);
    body += '\n';
  }

  if (hasItems(report.markdowns)) {
    report.markdowns.forEach(md => body += `${md}\n\n`);
  }

  if (!hasItems(report.errors) &&
      !hasItems(report.warnings) &&
      !hasItems(report.messages) &&
      !hasItems(report.markdowns)) {
    body += '✅ All checks passed!';
  }

  const { data: comments } = await github.rest.issues.listComments({
    owner: context.repo.owner,
    repo: context.repo.repo,
    issue_number: report.pr_number
  });

  const botComment = comments.find(c =>
    c.user.login === 'github-actions[bot]' &&
    c.body.includes('## Danger Report')
  );

  if (botComment) {
    await github.rest.issues.updateComment({
      owner: context.repo.owner,
      repo: context.repo.repo,
      comment_id: botComment.id,
      body: body
    });
  } else {
    await github.rest.issues.createComment({
      owner: context.repo.owner,
      repo: context.repo.repo,
      issue_number: report.pr_number,
      body: body
    });
  }

  // Fail if there are errors
  if (report.errors && report.errors.length > 0) {
    core.setFailed('Danger found errors');
  }
};
