/**
 * vault-docs.gs: turns the vault bundles your Mac writes to Google Drive "Vault-Bundles" into
 * native Google Docs in Drive "Vault-Docs", so Gemini (and other assistants with Drive access) can
 * search your notes. Gemini's Drive search reads Google Docs but not raw .md files.
 * Runs inside your own Google account as an Apps Script, every hour. Part of Personal OS:
 * scripts/build-vault-bundles.py makes the bundles; docs/connect-cloud-assistants.md has the setup.
 *
 * Each Doc holds one bundle as plain text (frontmatter, [[links]], checkboxes and the "=== FILE:"
 * delimiters intact) and is rewritten in place, so its link stays the same. Only bundles that
 * changed are copied. Drive itself converts the text into a Doc, which takes seconds even for a
 * 500,000-character bundle (DocumentApp.setText times out on bundles that size). A Doc is never
 * left half-made, one bad bundle does not stop the rest, and an existing Doc with the same title
 * is reused rather than duplicated.
 *
 * Set up once: script.google.com > New project > paste this file over Code.gs > Services (+) >
 * Drive API > Add > choose "setup" in the function menu > Run > approve. It creates Vault-Docs,
 * installs an hourly trigger and runs the first sync. Re-running setup is safe.
 * To stop it: delete the project's trigger (Triggers, the alarm-clock icon), then the Vault-Docs folder.
 *
 * Built to stay inside Google's limits for personal accounts: about 25 Docs in total (the limit is
 * 250 created a day), a progress record of about 3 KB (the limit is 9 KB per value), and a 3-minute
 * budget per run (the limit is 6), so a big first sync finishes over two or three runs.
 */

var SOURCE_FOLDER = 'Vault-Bundles';
var TARGET_FOLDER = 'Vault-Docs';
var TITLE_PREFIX = '[Vault] ';
var STATE_KEY = 'VAULT_DOCS_STATE';
var TIME_BUDGET_MS = 180000;
var MAX_CHARS = 1000000;
var GOOGLE_DOC = 'application/vnd.google-apps.document';

function setup() {
  requireDriveApi_();
  getOrCreateFolder_(TARGET_FOLDER);
  ScriptApp.getProjectTriggers().forEach(function (t) {
    if (t.getHandlerFunction() === 'syncVaultDocs') ScriptApp.deleteTrigger(t);
  });
  ScriptApp.newTrigger('syncVaultDocs').timeBased().everyHours(1).create();
  console.log('Hourly trigger installed. Running the first sync now.');
  syncVaultDocs();
}

function syncVaultDocs() {
  requireDriveApi_();
  var started = Date.now();
  var lock = LockService.getScriptLock();
  if (!lock.tryLock(1000)) {
    console.log('Another sync is still running; skipping this one.');
    return;
  }
  var failed = [];
  try {
    var source = getFolder_(SOURCE_FOLDER);
    if (!source) {
      console.log('No "' + SOURCE_FOLDER + '" folder in My Drive yet. The Mac mirror job creates it.');
      return;
    }
    var target = getOrCreateFolder_(TARGET_FOLDER);
    var props = PropertiesService.getScriptProperties();
    var state = JSON.parse(props.getProperty(STATE_KEY) || '{}');
    var seen = {};
    var listed = 0, updated = 0, unchanged = 0, complete = true;

    // Name order, so "00 START HERE" (the entry point) is always written first.
    var files = [];
    var it = source.getFiles();
    while (it.hasNext()) {
      var f = it.next();
      if (/\.md$/i.test(f.getName()) && !f.isTrashed()) files.push(f);
    }
    files.sort(function (a, b) { return a.getName() < b.getName() ? -1 : a.getName() > b.getName() ? 1 : 0; });

    for (var i = 0; i < files.length; i++) {
      var file = files[i];
      var name = file.getName();
      listed++;
      seen[name] = true;
      var modified = file.getLastUpdated().getTime();
      var rec = state[name];
      if (rec && rec.m >= modified && docAlive_(rec.d)) {
        unchanged++;
        continue;
      }
      if (Date.now() - started > TIME_BUDGET_MS) {
        complete = false;
        console.log('Time budget reached; the next run carries on.');
        break;
      }
      try {
        var text = file.getBlob().getDataAsString('UTF-8');
        if (text.length > MAX_CHARS) {
          text = text.substring(0, MAX_CHARS - 200) + '\n\n[... bundle truncated: too long for one Google Doc ...]\n';
        }
        var docId = writeDoc_(target, TITLE_PREFIX + name.replace(/\.md$/i, ''), text, rec ? rec.d : null);
        state[name] = { d: docId, m: modified };
        props.setProperty(STATE_KEY, JSON.stringify(state));
        updated++;
      } catch (e) {
        failed.push(name + ': ' + e.message);
      }
    }

    var removed = 0;
    if (complete && listed > 0) {
      Object.keys(state).forEach(function (n) {
        if (seen[n]) return;
        trash_(state[n].d);
        delete state[n];
        removed++;
      });
      if (removed) props.setProperty(STATE_KEY, JSON.stringify(state));
    }
    console.log('Bundles: ' + listed + ' listed, ' + updated + ' copied to Docs, ' + unchanged +
                ' unchanged, ' + failed.length + ' failed, ' + removed + ' removed' +
                (complete ? '.' : ' (partial run).'));
  } finally {
    lock.releaseLock();
  }
  if (failed.length) {
    // Raised after everything else is saved, so the run shows as failed and Google's
    // failure email reports it; the failed bundles are retried on the next run.
    throw new Error(failed.length + ' bundle(s) failed and will be retried next run: ' + failed.join(' | '));
  }
}

/** Writes text into the Doc for one bundle and returns its ID. Never leaves an empty Doc behind. */
function writeDoc_(folder, title, text, knownId) {
  var id = (knownId && docAlive_(knownId)) ? knownId : adoptDoc_(folder, title);
  if (!id) return createDoc_(folder, title, text);
  try {
    updateDoc_(id, title, text);
    return id;
  } catch (e) {
    // Rewriting in place failed: make a fresh Doc first, and only then trash the old one.
    console.log('Could not rewrite "' + title + '" in place (' + e.message + '); replacing it.');
    var fresh = createDoc_(folder, title, text);
    trash_(id);
    return fresh;
  }
}

/** Finds a live Doc with this title in Vault-Docs (for example one left by an earlier failed run). */
function adoptDoc_(folder, title) {
  var keep = null;
  var it = folder.getFilesByName(title);
  while (it.hasNext()) {
    var f = it.next();
    if (f.isTrashed() || f.getMimeType() !== GOOGLE_DOC) continue;
    if (!keep) {
      keep = f.getId();
    } else {
      f.setTrashed(true);
      console.log('Trashed a duplicate of "' + title + '" in ' + TARGET_FOLDER + '.');
    }
  }
  return keep;
}

function createDoc_(folder, title, text) {
  var blob = Utilities.newBlob(text, 'text/plain', title + '.txt');
  if (typeof Drive.Files.create === 'function') {
    return Drive.Files.create({ name: title, mimeType: GOOGLE_DOC, parents: [folder.getId()] }, blob,
                              { fields: 'id' }).id;
  }
  return Drive.Files.insert({ title: title, mimeType: GOOGLE_DOC, parents: [{ id: folder.getId() }] }, blob,
                            { convert: true }).id;
}

function updateDoc_(id, title, text) {
  var blob = Utilities.newBlob(text, 'text/plain', title + '.txt');
  if (typeof Drive.Files.create === 'function') {
    Drive.Files.update({ name: title }, id, blob, { fields: 'id' });
  } else {
    Drive.Files.update({ title: title }, id, blob, { convert: true });
  }
}

function requireDriveApi_() {
  if (typeof Drive === 'undefined' || !Drive.Files) {
    throw new Error('Turn on the Drive API first: in the editor, Services (+) > Drive API > Add. Then run this again.');
  }
}

function docAlive_(id) {
  try {
    return !DriveApp.getFileById(id).isTrashed();
  } catch (e) {
    return false;
  }
}

function trash_(id) {
  try {
    DriveApp.getFileById(id).setTrashed(true);
  } catch (e) {
    // already gone
  }
}

function getFolder_(name) {
  var it = DriveApp.getRootFolder().getFoldersByName(name);
  return it.hasNext() ? it.next() : null;
}

function getOrCreateFolder_(name) {
  return getFolder_(name) || DriveApp.getRootFolder().createFolder(name);
}

/** Run by hand to rebuild every Doc on the next sync (the Docs are reused, not duplicated). */
function forceFullResync() {
  var props = PropertiesService.getScriptProperties();
  var state = JSON.parse(props.getProperty(STATE_KEY) || '{}');
  Object.keys(state).forEach(function (n) { state[n].m = 0; });
  props.setProperty(STATE_KEY, JSON.stringify(state));
  console.log('Every Doc will be rewritten on the next sync.');
}
