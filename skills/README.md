# skills/

Repeatable playbooks. One folder per skill, containing a `SKILL.md` with YAML frontmatter (`name`, `description`: the description should say *when to use it*) and then the steps.

Write a skill the third time you explain the same process to an agent. Good skills encode: the exact steps in order, the house rules that apply (backups, verification), the gotchas that have burned you before, and what "done" means. Keep each under about 60 lines: a skill is a checklist with judgement, not documentation.

Included here:

- `personal-os-setup/`: the meta-skill. An agent interviews you and fills in this whole template.
- `memory-check/`: proves an agent really loaded `AGENTS.md` and can write to this repo.
- `weekly-review/`: an example ritual skill; customise it to your actual week or delete it.
