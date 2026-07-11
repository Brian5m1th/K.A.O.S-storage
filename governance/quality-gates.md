# Quality Gates — K.A.O.S CI Pipeline

## Gate Sequence

```
Lint → Type Check → Unit Tests → Coverage → Mutation → Security → Build Verify
```

## Gate 1: Lint & Style

- **Tool:** `ruff` (Python), `eslint` (TypeScript)
- **Rule:** Zero errors. Warnings must not increase.
- **Command:** `ruff check .`, `eslint desktop/src/`

## Gate 2: Mock Elimination

- **Tool:** `verify-no-mocks.ps1`
- **Rule:** Zero mock/fabricated data patterns.
- **Command:** `pwsh scripts/verify-no-mocks.ps1`

## Gate 3: Framework Isolation

- **Tool:** `verify-no-framework-imports.ps1`
- **Rule:** Desktop stores must not import frameworks directly.
- **Command:** `pwsh scripts/verify-no-framework-imports.ps1`

## Gate 4: Type Checks

- **Tool:** `mypy` (Python), `tsc --noEmit` (TypeScript)
- **Rule:** Zero type errors.
- **Command:** `mypy assistant/app/`, `npx tsc --noEmit`

## Gate 5: Unit Tests

- **Tool:** `pytest`, `vitest`
- **Rule:** All tests pass.
- **Command:** `uv run pytest`, `npm run test`

## Gate 6: Coverage

- **Target:** ≥ 80% line coverage for all controllers.
- **Tool:** `pytest --cov`, `vitest --coverage`
- **Enforcement:** Merge blocked if coverage drops.

## Gate 7: Mutation Score

- **Target:** Mutation score ≥ 60%.
- **Tool:** `mutmut` (Python), `stryker` (TypeScript)
- **Enforcement:** Advisory; merge warning if below target.

## Gate 8: Security Scan

- **Tool:** `bandit` (Python), `gitleaks` (secrets)
- **Rule:** Zero critical/high findings.
- **Command:** `bandit -r assistant/app/`, `gitleaks detect`

## Gate 9: Dependency Check

- **Tool:** `pip-audit`, `npm audit`
- **Rule:** Zero critical vulnerabilities. License compliance check.
- **Enforcement:** Merge blocked on critical CVEs.

## Gate 10: Build Verify

- **Tool:** `docker build`, `npm run build`
- **Rule:** Build succeeds without errors.
- **Enforcement:** Merge blocked if build fails.

## Gate 11: ADR Compliance

- **Rule:** PRs changing config, schemas, or dependencies must include ADR.
- **Enforcement:** Manual review + CI warning.

---

## Running All Gates

```bash
# Backend
ruff check assistant/app/
mypy assistant/app/
bandit -r assistant/app/
uv run pytest --cov=assistant/app --cov-report=term
pip-audit

# Frontend
npx eslint desktop/src/
npx tsc --noEmit
npm run test -- --coverage
npm audit

# Cross-cutting
pwsh scripts/verify-no-mocks.ps1
pwsh scripts/verify-no-framework-imports.ps1
gitleaks detect
```
