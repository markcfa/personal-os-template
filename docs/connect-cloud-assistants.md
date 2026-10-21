# Connecting your cloud assistants

What each assistant can reach, and how to set it up. Menus and plan rules change often: this was checked in October 2026, so trust what you see on screen over these steps.

| Assistant | Reads this repo | Reads your notes | Gets your profile from |
|---|---|---|---|
| ChatGPT | yes, through its GitHub app (read-only in chat) | yes, through Google Drive (`Vault-Mirror/`) | custom instructions, optionally a project file |
| Gemini | as a snapshot you import per chat | yes, through Google Workspace (Drive) | a Gem |
| Venice | no | no | its system prompt |
| Meta AI | no | no | its memory |

## Before you start: decide what goes where

- **This repo** is pushed to GitHub and readable by ChatGPT. Keep it free of sensitive detail (see AGENTS.md).
- **Your notes** reach ChatGPT and Gemini through the Drive mirror. Connecting Google Drive or Gmail gives an assistant your whole account, not one folder. If any of it is sensitive (legal, medical, financial), think before you connect, and take advice where it matters.
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
3. **Your notes:** gemini.google.com/apps › connect Google Workspace (Gmail, Drive, Docs).
4. **Profile:** Gems › New Gem. Paste your instructions and profile into Instructions; add `cloud-llm-context.md` under Knowledge. Google announced that Gems migrate to "skills" from 17 November 2026.
5. **This repo:** in a chat, + › Import code › your repo URL (it asks to link GitHub the first time), or Upload folder for the live copy on your Mac. Either way it is a one-off snapshot for that chat (one repo per chat, up to 5,000 files and 100 MB).

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
