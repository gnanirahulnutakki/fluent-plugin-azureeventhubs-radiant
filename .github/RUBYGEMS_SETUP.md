# RubyGems Automated Publishing Setup

This guide explains how to set up automated publishing to RubyGems via GitHub Actions.

## Prerequisites

1. A RubyGems.org account
2. Repository admin access on GitHub
3. The gem already published at least once manually

## Step 1: Create RubyGems API Key

1. Go to https://rubygems.org/settings/edit
2. Scroll to "API Keys" section
3. Click "New API Key"
4. **Name**: `github-actions-fluent-plugin-azureeventhubs-radiant`
5. **Scopes**: Select "Push rubygems"
6. **Index Rubygems**: Select your gem: `fluent-plugin-azureeventhubs-radiant`
7. **MFA**: Choose "Enable MFA" for security
8. Click "Create"
9. **IMPORTANT**: Copy the API key immediately - you won't see it again!

## Step 2: Add API Key to GitHub Secrets

1. Go to your GitHub repository: https://github.com/gnanirahulnutakki/fluent-plugin-azureeventhubs-radiant
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. **Name**: `RUBYGEMS_API_KEY`
5. **Secret**: Paste the API key from Step 1
6. Click **Add secret**

## Step 3: How to Publish a New Version

### Automatic Publishing (Recommended)

1. **Update version** in `lib/fluent/plugin/azureeventhubs_radiant/version.rb`:
   ```ruby
   VERSION = "0.1.1"  # Increment version
   ```

2. **Update CHANGELOG.md** with new changes

3. **Commit changes**:
   ```bash
   git add .
   git commit -m "Bump version to 0.1.1"
   git push origin main
   ```

4. **Create and push a git tag**:
   ```bash
   git tag v0.1.1
   git push origin v0.1.1
   ```

5. **GitHub Actions will automatically**:
   - Run tests on Ruby 3.0, 3.1, 3.2, 3.3
   - Build the gem
   - Publish to RubyGems
   - Create a GitHub Release with the gem file

### Manual Publishing (Fallback)

If automated publishing fails, you can always publish manually:

```bash
gem build fluent-plugin-azureeventhubs-radiant.gemspec
gem push fluent-plugin-azureeventhubs-radiant-*.gem --otp YOUR_OTP_CODE
```

## Workflow Files

### `.github/workflows/publish.yml`
- Triggers on git tags matching `v*`
- Runs tests, builds gem, publishes to RubyGems
- Creates GitHub Release

### `.github/workflows/ci.yml`
- Runs on every push to main and all PRs
- Tests on multiple Ruby versions
- Runs RuboCop linting
- Builds gem to verify it compiles

## Troubleshooting

### "401 Unauthorized" Error
- Check that `RUBYGEMS_API_KEY` secret is set correctly
- Verify the API key has "Push rubygems" scope
- Ensure the API key hasn't expired

### "This rubygem could not be published" Error
- Verify version number is incremented (can't republish same version)
- Check CHANGELOG.md is updated
- Ensure gemspec is valid

### MFA Issues
- Automated publishing uses API keys, so MFA is handled automatically
- Manual publishing requires `--otp` flag

## Security Best Practices

1. ✅ Use scoped API keys (not global)
2. ✅ Enable MFA on RubyGems account
3. ✅ Limit API key to specific gem
4. ✅ Use GitHub secrets (never commit API keys)
5. ✅ Rotate API keys periodically

## Verification

After setting up, verify the workflow:

1. Make a minor change (update README)
2. Commit: `git commit -am "Test workflow"`
3. Tag: `git tag v0.1.1-test`
4. Push: `git push origin v0.1.1-test`
5. Check: https://github.com/gnanirahulnutakki/fluent-plugin-azureeventhubs-radiant/actions

If successful, delete the test tag:
```bash
git tag -d v0.1.1-test
git push origin :refs/tags/v0.1.1-test
```

## Questions?

Open an issue at: https://github.com/gnanirahulnutakki/fluent-plugin-azureeventhubs-radiant/issues
