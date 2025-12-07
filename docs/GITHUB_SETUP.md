# GitHub Repository Settings Guide

This document outlines the recommended settings for the GitHub repository.

---

## General Settings

### Repository Details

- **Description**: Production-ready Azure project template with FastAPI, React, and Bicep IaC
- **Website**: https://phoenixvc.co.za
- **Topics**: 
  - azure
  - fastapi
  - react
  - bicep
  - infrastructure-as-code
  - template
  - python
  - typescript
  - docker
  - kubernetes

### Features

- **Issues** - Enable issue tracking
- **Projects** - Enable project boards
- **Wiki** - Enable wiki
- **Discussions** - Enable discussions
- **Sponsorships** - Disable (unless needed)

### Pull Requests

- Allow merge commits
- Allow squash merging (default)
- Allow rebase merging
- Automatically delete head branches

---

## Branch Protection Rules

### Main Branch

**Settings -> Branches -> Add rule**

Branch name pattern: `main`

#### Protect matching branches

- **Require a pull request before merging**
  - Require approvals: **1**
  - Dismiss stale pull request approvals when new commits are pushed
  - Require review from Code Owners
  
- **Require status checks to pass before merging**
  - Require branches to be up to date before merging
  - Required status checks:
    - `lint`
    - `test`
    - `security`
    - `validate-bicep`

- **Require conversation resolution before merging**

- **Require signed commits**

- **Require linear history**

- **Include administrators**

- **Restrict who can push to matching branches**
  - Add: Maintainers only

### Develop Branch

Branch name pattern: `develop`

- **Require a pull request before merging**
  - Require approvals: **1**
  
- **Require status checks to pass before merging**
  - Required status checks:
    - `lint`
    - `test`

---

## Secrets and Variables

**Settings -> Secrets and variables -> Actions**

### Repository Secrets

Add these secrets for CI/CD:

```
AZURE_CREDENTIALS          # Azure service principal credentials
AZURE_SUBSCRIPTION_ID      # Azure subscription ID
AZURE_TENANT_ID           # Azure tenant ID
APP_SERVICE_NAME          # App Service name
RESOURCE_GROUP            # Resource group name
CODECOV_TOKEN             # Codecov token (optional)
```

### Repository Variables

```
AZURE_LOCATION            # e.g., westeurope
ENVIRONMENT               # e.g., dev, staging, prod
```

---

## Labels

**Settings -> Labels**

### Type Labels

- `type: bug` - Bug reports (color: #d73a4a)
- `type: feature` - Feature requests (color: #a2eeef)
- `type: enhancement` - Enhancements (color: #84b6eb)
- `type: documentation` - Documentation (color: #0075ca)
- `type: refactor` - Code refactoring (color: #fbca04)
- `type: test` - Testing (color: #1d76db)
- `type: chore` - Maintenance (color: #fef2c0)

### Priority Labels

- `priority: critical` - Critical priority (color: #b60205)
- `priority: high` - High priority (color: #d93f0b)
- `priority: medium` - Medium priority (color: #fbca04)
- `priority: low` - Low priority (color: #0e8a16)

### Status Labels

- `status: in-progress` - In progress (color: #d4c5f9)
- `status: blocked` - Blocked (color: #e99695)
- `status: ready` - Ready for review (color: #c2e0c6)
- `status: needs-review` - Needs review (color: #f9d0c4)

### Other Labels

- `good first issue` - Good for newcomers (color: #7057ff)
- `help wanted` - Help wanted (color: #008672)
- `duplicate` - Duplicate issue (color: #cfd3d7)
- `invalid` - Invalid issue (color: #e4e669)
- `wontfix` - Won't fix (color: #ffffff)
- `dependencies` - Dependency updates (color: #0366d6)
- `security` - Security issues (color: #ee0701)

---

## GitHub Apps

### Recommended Apps

Install these from GitHub Marketplace:

1. **Dependabot**
   - Automated dependency updates
   - Security vulnerability alerts

2. **CodeQL**
   - Code scanning for security vulnerabilities
   - Automated security analysis

3. **Codecov**
   - Code coverage reporting
   - Coverage trends

4. **Renovate**
   - Alternative to Dependabot
   - More configuration options

---

## Insights Settings

**Insights -> Community**

Ensure all items are checked:

- Description
- README
- Code of conduct
- Contributing guidelines
- License
- Issue templates
- Pull request template

---

## Notifications

**Settings -> Notifications**

### Email Notifications

- Pull request reviews
- Pull request pushes
- Comments on issues and pull requests
- CI activity

### Watching

Set repository to **Watching** for:
- All activity
- Issues
- Pull requests
- Releases

---

## Pages (Optional)

**Settings -> Pages**

If hosting documentation:

- **Source**: Deploy from branch
- **Branch**: `gh-pages` or `main` -> `/docs`
- **Custom domain**: docs.phoenixvc.co.za (optional)

---

## Webhooks (Optional)

**Settings -> Webhooks**

Add webhooks for:

- Slack notifications
- Discord notifications
- Custom CI/CD triggers

---

## Project Boards

**Projects -> New project**

### Kanban Board

Columns:
1. **Backlog** - New issues
2. **To Do** - Prioritized work
3. **In Progress** - Active work
4. **In Review** - Under review
5. **Done** - Completed

### Automation

- Move issues to "In Progress" when assigned
- Move PRs to "In Review" when opened
- Move to "Done" when closed

---

## Milestones

Create milestones for releases:

- **v1.0.0** - Initial release
- **v1.1.0** - Feature additions
- **v2.0.0** - Major updates

---

## Repository Templates

### Issue Templates

Already created in `.github/ISSUE_TEMPLATE/`:
- bug_report.md
- feature_request.md
- question.md

### PR Template

Already created: `.github/pull_request_template.md`

---

## Security

**Settings -> Security**

### Security Policy

Create `SECURITY.md`:

```markdown
# Security Policy

## Reporting a Vulnerability

Email: security@phoenixvc.co.za

Please include:
- Description of vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

We will respond within 48 hours.
```

### Dependabot Alerts

- Enable Dependabot alerts
- Enable Dependabot security updates
- Enable Dependabot version updates

### Code Scanning

- Enable CodeQL analysis
- Enable secret scanning
- Enable push protection

---

## Releases

### Creating Releases

1. Tag version: `git tag -a v1.0.0 -m "Release v1.0.0"`
2. Push tag: `git push origin v1.0.0`
3. Create release on GitHub
4. Add release notes from CHANGELOG.md
5. Attach binaries/artifacts if needed

### Release Automation

Use GitHub Actions to automate:
- Version bumping
- Changelog generation
- Release creation
- Asset uploads

---

## Social Preview

**Settings -> General -> Social preview**

Upload a custom image (1280x640px):
- Project logo
- Key features
- Technology stack

---

## Checklist

Use this checklist when setting up a new repository:

- [ ] Set description and website
- [ ] Add topics/tags
- [ ] Configure branch protection
- [ ] Add required secrets
- [ ] Create labels
- [ ] Install GitHub Apps
- [ ] Set up project board
- [ ] Create milestones
- [ ] Enable security features
- [ ] Configure notifications
- [ ] Upload social preview image
- [ ] Create SECURITY.md
- [ ] Test CI/CD workflows

---

## Support

For questions about repository settings:
- Email: support@phoenixvc.co.za
- GitHub Discussions
- Internal documentation

---

<div align="center">

**Built with love by [Phoenix Venture Capital](https://phoenixvc.co.za)**

</div>
