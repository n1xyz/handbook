# AI usage guide

Use AI tools as assistants for engineering work. You remain responsible for the code, configuration, tests, and decisions you submit.

## Protect sensitive information

Do not paste credentials, private keys, access tokens, customer data, production logs with identifying information, unpublished vulnerabilities, or confidential business material into an AI tool. Remove secrets and reduce examples to the smallest useful case. Treat generated output as untrusted input until you review it.

## Use AI for bounded tasks

Good uses include explaining unfamiliar code, proposing test cases, summarizing public documentation, checking a small refactor, and generating a first draft of repetitive documentation. State the repository, file scope, constraints, and required checks in the prompt.

Avoid delegating irreversible actions, security decisions, production changes, or broad repository edits without a human review step. Do not ask an AI tool to bypass repository permissions, review requirements, safety controls, or audit trails.

## Review generated output

Read every generated line. Check behavior against the surrounding code, repository conventions, dependency versions, and current documentation. Look for invented APIs, unsafe defaults, missing error handling, leaked secrets, and changes outside the requested scope.

Require tests for behavior changes. Run the narrowest relevant checks first, then the repository's standard formatter, linter, type checker, and test suite. Record any checks you could not run and why.

## Commit and review discipline

Keep AI-assisted work on a branch. Use small commits with descriptive messages. Include the purpose of the change and the checks you ran in the pull request. Never commit generated credentials or unreviewed code. A maintainer must review the final diff before merge.

## A practical prompt format

Include these details:

1. The goal and the exact files in scope.
2. Repository conventions and acceptance criteria.
3. Inputs and assumptions, with secrets removed.
4. Required tests and formatting commands.
5. A request for a proposed diff before any file is changed.

AI assistance improves speed when the task stays bounded and the review remains human-owned.
