# prompts/

Reusable prompts. One `.md` per prompt, descriptive filename, with a header line saying where it is used.

- `local-agent-bootstrap.md`: startup prompt for a local agent that cannot load `AGENTS.md` by itself.
- `cloud-llm-context.md`: your profile for cloud assistants that cannot read your files (a ChatGPT project file, a Gemini Gem's knowledge, Venice). Upload or paste it.
- `cloud-llm-context-short.md`: the same in under 1,000 characters, for custom-instruction and system-prompt boxes.
- `other-ai-digest.md`: the prompt for the optional daily Claude task that reads your other assistants' chats and files a digest in Google Drive.

Both context files stay free of anything covered by the Sensitive rule in AGENTS.md: they are committed to this repo. If you want an assistant to know personal details, type those into that assistant's own settings instead. Update both files together.
