# Connecting your cloud assistants

What each assistant can reach, and how to set it up. Menus and plan rules change often: this was checked in October 2026, so trust what you see on screen over these steps.

| Assistant | Reads this repo | Reads your notes | Gets your profile from |
|---|---|---|---|
| ChatGPT | yes, through its GitHub app (read-only in chat) | yes, through Google Drive (`Vault-Mirror/`) | custom instructions, optionally a project file |
| Gemini | as a snapshot you import per chat | yes, as Google Docs in `Vault-Docs/` (it cannot read .md files) | a Gem (a skill from 17 November 2026) |
| Venice | no | no | its system prompt |
| Meta AI | no | no | its memory |

## Before you start: decide what goes where

- **This repo** is pushed to GitHub and readable by ChatGPT. Keep it free of sensitive detail (see AGENTS.md).
- **Your notes** reach ChatGPT through the Drive mirror and Gemini through the Google Docs made from it (see Gemini, step 4). Connecting Google Drive or Gmail gives an assistant your whole account, not one folder. If any of it is sensitive (legal, medical, financial), think before you connect, and take advice where it matters.
- **Instruction boxes** go with every chat in that assistant, including image work. Anything you type there is your choice; the context pack in this repo stays generic.

## ChatGPT

1. **Profile:** Settings › Personalization › Custom instructions. Put how you want answers in the instructions box and who you are in the "more about you" box (start from `prompts/cloud-llm-context-short.md`). Both boxes have character limits; the short pack fits.
2. **This repo:** Settings › Plugins › GitHub › connect. Then on GitHub, Settings › Applications › Installed GitHub Apps › the ChatGPT app › Configure › **Only select repositories** › pick your Personal OS repo. The app's GitHub permissions include write access to code, used by Codex; chat itself only reads.
3. **Your notes:** Settings › Plugins › Google Drive › connect.
4. **Permissions:** for Gmail and Google Drive, set the plugin permission to **Allow low-risk tools**, not "Allow all tools", so ChatGPT cannot send, delete or share without asking.
5. **Training:** Settings › Data controls › "Improve the model for everyone": your call.
6. **Test:** "Using GitHub, read AGENTS.md in <your repo> and summarise it", then "Search my Google Drive for Vault-Mirror and summarise my latest daily note."

## Gemini

1. **Keep Activity** (myactivity.google.com/product/gemini) must be on for Gemini to use your Google apps. With it on, Google can use your chats to improve its models and human reviewers may read some of them. Temporary Chats are not used for training.
2. **Gmail:** Gmail › Settings › General › Smart features must be on, or Gemini cannot connect to Gmail.
3. **Connect Drive:** gemini.google.com/apps › connect Google Workspace (Gmail, Drive, Docs).
4. **Your notes as Google Docs.** Gemini's Drive search reads Google Docs, Sheets, Slides and PDFs but not .md files, so the mirror job also packs your notes into about 25 bundles in `My Drive/Vault-Bundles/`, and a small Google Apps Script in your own account turns them into Google Docs titled `[Vault] ...` in `My Drive/Vault-Docs/`, every hour. Set it up once, after the mirror has run (check `Vault-Bundles/` exists):
   1. In Terminal: `pbcopy < ~/personal-os/scripts/vault-docs.gs` (copies the script).
   2. script.google.com › New project. Rename it "Vault Docs". Select everything in Code.gs, paste over it, press Cmd+S.
   3. In the left sidebar: Services (+) › Drive API › Add (leave it on v3).
   4. In the function menu at the top choose `setup`, click Run, then Review permissions › your account. Google warns the app is unverified because it is your own script: Advanced › Go to Vault Docs › Allow.
   5. The log ends with a line such as "Bundles: 25 listed, 25 copied to Docs". Check `Vault-Docs/` in Drive. A very large vault can take two or three hourly runs.

   Don't edit or share the `[Vault]` Docs: each run overwrites them, and together they hold every note you mirror. To stop it, open the project at script.google.com › Triggers (the alarm-clock icon) › delete the trigger, then delete `Vault-Docs/`.
5. **Profile:** Gems › New Gem. Paste your instructions and profile into Instructions (optionally add `cloud-llm-context.md` under Knowledge), and end the instructions with this line so it uses your notes:
   `My notes: when a question needs my notes, search my Google Drive for Docs whose titles start with "[Vault]". Read "[Vault] 00 START HERE" first; its bundle map says which Doc to open next. Name the note you used from its "=== FILE:" line.`
   Google is turning Gems into "skills" from 17 November 2026: existing Gems migrate automatically, skills sit under Settings and are run with a slash command in the chat box. After that date, create a skill with the same instructions instead of a Gem.
6. **Test:** "Read [Vault] 00 START HERE in my Drive and list my five most recent open tasks." It should name the note it used from its `=== FILE:` line.
7. **This repo:** in a chat, + › Import code › your repo URL (it asks to link GitHub the first time), or Upload folder for the live copy on your Mac. Either way it is a one-off snapshot for that chat (one repo per chat, up to 5,000 files and 100 MB).

## Venice

Venice keeps chat history in your browser, not on its servers, and has no connection to your files.

1. Settings (your name, bottom left) › Text › System Prompt › Add. Name it, paste your profile and instructions, keep it Active, Save.
2. For a chat that needs more, upload `cloud-llm-context.md` into that chat.

## Meta AI

Meta's Muse agent and its connectors were available in the US and Canada only as of October 2026. In the Meta AI app or at meta.ai:

1. Start a chat, paste your profile and say "Remember this about me."
2. Look for a Memory section in Settings to confirm it saved (the menu differs between the app and the website).

## Getting work back into Claude

None of these services can write to your files. To let Claude see what you do in them, set up the optional daily digest in `prompts/other-ai-digest.md`.
