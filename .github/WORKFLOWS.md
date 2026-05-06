# GitHub Actions Workflows for BuildGrid Helm Chart

This directory contains GitHub Actions workflows for automated testing, validation, and releasing of the BuildGrid Helm chart.

## Workflows

### 1. `helm-lint.yml` - Chart Linting
**Triggered**: On push/PR to main, when chart files change

**Purpose**: Validates Helm chart syntax and structure

**Jobs**:
- `lint` - Run helm lint with strict mode
- `values-schema` - Validate YAML syntax of all values files
- `documentation` - Check for required documentation files

**What it checks**:
- ✅ Chart YAML syntax
- ✅ Template syntax
- ✅ Values file YAML validity
- ✅ README and CHANGELOG exist
- ✅ Version format (x.y.z)
- ✅ No unresolved template variables
- ✅ Deprecated API versions

**When to check locally**:
```bash
helm lint ./buildgrid-helm --strict
```

---

### 2. `helm-test.yml` - Functional Testing
**Triggered**: On push/PR to main, when chart files change

**Purpose**: Tests chart functionality on actual Kubernetes clusters

**Jobs**:
- `test-k3s` - Test on K3S 1.27, 1.28, 1.29 (matrix strategy)
- `test-versions` - Test with different value files
- `lint-helm-chart` - Lint with helm lint

**What it tests**:
- ✅ Dry-run installation
- ✅ Template rendering
- ✅ Manifest validation (kubeval)
- ✅ Actual installation on K3S
- ✅ Pod readiness
- ✅ Helm upgrade functionality
- ✅ Multiple value configurations
- ✅ Pod logs inspection

**Test scenarios**:
1. Default values
2. Production values
3. Bihar values
4. Development values

**Expected behavior**:
- All templates render without errors
- Manifests pass kubeval validation
- Pods become ready within 5 minutes
- Upgrade completes successfully

---

### 3. `helm-release.yml` - Release & Publish
**Triggered**: 
- Automatically on git tag push (e.g., `git tag v0.2.0 && git push origin v0.2.0`)
- Manually via `workflow_dispatch`

**Purpose**: Package and publish the chart to GitHub Releases and Helm repository

**Jobs**:
- `release` - Create GitHub release with packaged chart
- `publish-chart` - Update Helm repository index and deploy to gh-pages
- `notify-release` - Create release summary

**What it does**:
- ✅ Verifies version matches Chart.yaml
- ✅ Packages chart as `.tgz`
- ✅ Creates GitHub release with artifacts
- ✅ Updates Helm repository index
- ✅ Publishes to gh-pages branch
- ✅ Generates release summary in Markdown

**Installation after release**:
```bash
# From GitHub repository
git clone https://github.com/hanthor/buildgrid-helm.git
cd buildgrid-helm
git checkout v0.2.0
helm install buildgrid . -n buildgrid --create-namespace

# From packaged chart
helm install buildgrid buildgrid-0.2.0.tgz -n buildgrid

# From Helm repository
helm repo add buildgrid https://hanthor.github.io/buildgrid-helm
helm repo update
helm install buildgrid buildgrid/buildgrid -n buildgrid
```

---

### 4. `security-scan.yml` - Security Analysis
**Triggered**: 
- On push/PR to main
- Weekly schedule (Sunday midnight)

**Purpose**: Scans chart for security vulnerabilities and compliance

**Jobs**:
- `security-scan` - Run Trivy security scanner
- `policy-check` - Validate RBAC and Network Policies
- `dependency-check` - Check chart dependencies
- `changelog-check` - Validate CHANGELOG format

**What it checks**:
- ✅ Privileged containers
- ✅ Root user execution
- ✅ Missing resource limits
- ✅ Missing health probes
- ✅ RBAC configuration
- ✅ Network policies
- ✅ Chart dependencies
- ✅ CHANGELOG entries

**Severity levels**:
- CRITICAL - Build fails, must fix
- HIGH - Warnings shown
- MEDIUM/LOW - Informational

**Scan results**: Uploaded to GitHub Security tab

---

### 5. `quality-checks.yml` - Code Quality
**Triggered**: On push/PR to main and develop branches

**Purpose**: Ensures documentation and code quality standards

**Jobs**:
- `markdown-lint` - Validate Markdown syntax
- `yaml-lint` - Lint YAML files
- `readme-check` - Verify README structure
- `chart-metadata` - Validate Chart.yaml
- `values-documentation` - Check values.yaml comments
- `link-check` - Verify documentation links
- `helm-best-practices` - Check Helm conventions

**What it checks**:
- ✅ Markdown formatting
- ✅ YAML syntax validity
- ✅ Required README sections
- ✅ Chart.yaml completeness
- ✅ Values documentation coverage
- ✅ Documentation link validity
- ✅ Helm naming conventions
- ✅ Kubernetes label standards

**Pass/Fail criteria**:
- ✅ All Markdown valid
- ✅ All YAML parseable
- ✅ Required sections present
- ✅ Version format correct
- ✅ No broken links

---

## How to Use

### Local Testing (Before Committing)

```bash
# 1. Lint the chart
helm lint ./buildgrid-helm --strict

# 2. Template rendering
helm template buildgrid ./buildgrid-helm

# 3. Dry-run install
helm install buildgrid ./buildgrid-helm \
  --dry-run --debug

# 4. YAML validation
yamllint buildgrid-helm/values.yaml
```

### Making a Release

```bash
# 1. Update version in Chart.yaml
# 2. Update CHANGELOG.md with release notes
# 3. Commit changes
git add Chart.yaml CHANGELOG.md
git commit -m "chore: release v0.3.0"

# 4. Create and push tag (triggers workflow)
git tag -a v0.3.0 -m "BuildGrid Helm Chart 0.3.0"
git push origin main
git push origin v0.3.0

# 5. Watch workflow run
# - Go to Actions tab in GitHub
# - Monitor helm-release.yml
# - Release will auto-publish to GitHub Releases and Helm repo
```

### Viewing Workflow Results

1. **GitHub Actions Dashboard**
   - https://github.com/hanthor/buildgrid-helm/actions

2. **Workflow Details**
   - Click on workflow run
   - View job logs
   - Download artifacts

3. **Security Scanning**
   - https://github.com/hanthor/buildgrid-helm/security/code-scanning

4. **Releases**
   - https://github.com/hanthor/buildgrid-helm/releases

5. **GitHub Pages (Helm Repo)**
   - https://hanthor.github.io/buildgrid-helm

---

## Workflow Configuration

### Required Secrets

All workflows use only public GitHub features. No secrets required!

If you want to publish to a private Helm repository, add:
- `HELM_REPO_URL` - Your Helm repository URL
- `HELM_REPO_USERNAME` - Repository username
- `HELM_REPO_PASSWORD` - Repository password

### Customization

#### Change K3S versions tested
Edit `helm-test.yml`:
```yaml
matrix:
  k3s-version: [ 'v1.27', 'v1.28', 'v1.29', 'v1.30' ]
```

#### Change release triggers
Edit `helm-release.yml`:
```yaml
on:
  push:
    tags:
      - 'v[0-9]+.[0-9]+.[0-9]+'
      - 'release-*'  # Add more patterns
```

#### Modify security thresholds
Edit `security-scan.yml`:
```yaml
severity: 'CRITICAL,HIGH,MEDIUM'  # Add MEDIUM
```

---

## Best Practices

### For Contributors

1. **Before opening a PR**:
   ```bash
   helm lint ./buildgrid-helm --strict
   helm template buildgrid ./buildgrid-helm
   ```

2. **PR requirements**:
   - ✅ All workflows pass
   - ✅ No security warnings
   - ✅ Documentation updated
   - ✅ CHANGELOG.md updated
   - ✅ Version bumped (if releasing)

3. **Commit messages**:
   ```
   feat: add new feature
   fix: resolve issue
   chore: update dependencies
   docs: improve documentation
   ```

### For Maintainers

1. **Release checklist**:
   - [ ] Update CHANGELOG.md
   - [ ] Bump version in Chart.yaml
   - [ ] Verify all tests pass
   - [ ] Create annotated tag
   - [ ] Push tag to trigger release workflow
   - [ ] Verify release published to GitHub
   - [ ] Verify Helm repo index updated

2. **Post-release**:
   - [ ] Verify GitHub release page
   - [ ] Test chart installation from release
   - [ ] Update any documentation sites
   - [ ] Announce release to users

---

## Troubleshooting

### Workflow won't trigger

**Issue**: Changes pushed but workflows not running

**Solutions**:
1. Check file paths match workflow triggers
2. Verify branch name is main
3. Ensure commit pushed (not just local)
4. Check GitHub Actions enabled in repository settings

### Tests failing locally but passing in CI

**Issue**: Local environment differs from CI

**Solutions**:
1. Use same Kubernetes version as CI (K3S v1.27+)
2. Run `helm lint --strict` locally
3. Check Docker for consistent image availability
4. Review workflow logs for specific errors

### Release not publishing

**Issue**: Tag pushed but release not created

**Solutions**:
1. Verify tag format: `v0.2.0` (not `0.2.0`)
2. Check Chart.yaml version matches tag
3. Verify git tag is annotated: `git tag -a v0.2.0`
4. Check GitHub token has release permissions

### Helm repo not updating

**Issue**: New chart not available from Helm repo

**Solutions**:
1. Check GitHub Pages enabled in repository settings
2. Verify gh-pages branch exists
3. Wait a few minutes for GitHub Pages to rebuild
4. Run `helm repo update` locally
5. Check deployment to gh-pages in workflow

---

## Monitoring & Alerts

### Set up notifications

1. **GitHub Actions Notifications**
   - Account Settings → Notifications
   - Configure workflow failure alerts

2. **Repository Watch**
   - Click Watch → Custom → Select Actions
   - Get notified on workflow failures

3. **Slack Integration** (Optional)
   ```yaml
   - name: Send Slack notification
     uses: slackapi/slack-github-action@v1
     if: failure()
     with:
       webhook-url: ${{ secrets.SLACK_WEBHOOK }}
   ```

---

## Documentation

- [Helm Chart Best Practices](https://helm.sh/docs/chart_best_practices/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Trivy Security Scanner](https://github.com/aquasecurity/trivy)
- [kubeval - Kubernetes Manifest Validation](https://www.kubeval.com/)

---

**Last Updated**: May 6, 2026  
**Status**: ✅ Production Ready  
**Version**: 1.0
