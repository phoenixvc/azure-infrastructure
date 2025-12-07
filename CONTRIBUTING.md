# Contributing to Azure Project Template

Thanks for your interest in contributing!

## Quick Start

1. **Fork the repo**
```bash
gh repo fork phoenixvc/azure-project-template --clone
cd azure-project-template
```

2. **Create a branch**
```bash
git checkout -b feature/your-feature-name
```

3. **Make your changes**
   - Follow existing code style
   - Add tests for new features
   - Update documentation

4. **Test locally**
```bash
# Run linting
ruff check src/
black --check src/
isort --check-only src/

# Run tests
pytest tests/ -v

# Test Bicep
bicep build infra/main.bicep
```

5. **Commit and push**
```bash
git add .
git commit -m "feat: Add your feature"
git push origin feature/your-feature-name
```

6. **Create Pull Request**
   - Use descriptive title
   - Reference any issues
   - Explain what and why

## Commit Convention

We use [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation only
- `style:` - Code style (formatting, etc)
- `refactor:` - Code refactoring
- `test:` - Adding tests
- `chore:` - Maintenance tasks

**Examples:**
```
feat: Add PostgreSQL connection pooling
fix: Resolve CORS issue in API
docs: Update deployment guide
```

## Code Style

### Python
- Use **Black** for formatting
- Use **Ruff** for linting
- Use **isort** for import sorting
- Follow **PEP 8**
- Add type hints

### Bicep
- Use consistent naming
- Add parameter descriptions
- Include examples in comments

## Architecture Guidelines

### Standard Architecture
- Keep it simple
- Focus on readability
- Suitable for MVPs

### Hexagonal Architecture
- Clear domain/application/infrastructure separation
- Use dependency injection
- Write unit tests for domain logic

## Testing

- **Unit tests** - Test individual functions/classes
- **Integration tests** - Test component interactions
- **E2E tests** - Test full workflows

Aim for >80% code coverage.

## Documentation

Update docs when you:
- Add new features
- Change APIs
- Modify configuration
- Update dependencies

## Questions?

Open an issue or start a discussion. We're here to help!

## License

By contributing, you agree your contributions will be licensed under the MIT License.
