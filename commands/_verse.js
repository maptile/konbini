#!/usr/bin/env node
'use strict';

const https = require('https');
const { execFileSync } = require('child_process');

const VOTD_URL = 'https://www.biblegateway.com/votd/get/?format=json&version=esv';
const TIMEOUT_MS = 3000;
const VERBOSE = process.argv.includes('--verbose');
const NO_NEWLINE = process.argv.includes('-n');

const VERSE_POOL = [
  'John 3:16',
  'Psalm 23:1',
  'Romans 8:28',
  'Philippians 4:6',
  'Proverbs 3:5-6',
  'Isaiah 40:31',
  'Matthew 5:3-4',
  'Matthew 11:28',
  '2 Timothy 1:7',
  '1 Corinthians 13:4-5',
];

function decodeHtmlEntities(str) {
  if (!str) return '';
  return str
    .replace(/&nbsp;/g, ' ')
    .replace(/&ldquo;/g, '“')
    .replace(/&rdquo;/g, '”')
    .replace(/&lsquo;/g, '‘')
    .replace(/&rsquo;/g, '’')
    .replace(/&amp;/g, '&')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&#x27;/g, "'")
    .replace(/&#x2F;/g, '/')
    .replace(/&#([0-9]+);/g, (_, n) => String.fromCharCode(Number(n)))
    .replace(/&#x([0-9a-fA-F]+);/g, (_, n) => String.fromCharCode(parseInt(n, 16)));
}

function logVerbose(...args) {
  if (VERBOSE) console.error('[verse]', ...args);
}

function stripTags(str) {
  return (str || '').replace(/<[^>]+>/g, '');
}

function normalizeSpace(str) {
  return (str || '').replace(/[\t\n\r ]+/g, ' ').trim();
}

function pickRandomRef() {
  return VERSE_POOL[Math.floor(Math.random() * VERSE_POOL.length)];
}

function diathekeLookup(ref) {
  try {
    const out = execFileSync('diatheke', ['-b', 'ESV', '-k', ref], {
      timeout: 1500,
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'ignore'],
    });
    const cleaned = normalizeSpace(stripTags(out));
    return cleaned || null;
  } catch (_) {
    return null;
  }
}

function fallbackLocal() {
  const ref = pickRandomRef();
  const text = diathekeLookup(ref);
  return text || 'ESV verse unavailable (check diatheke installation).';
}

function parseJson(jsonText) {
  if (!jsonText) return null;
  logVerbose('json bytes', jsonText.length);
  let data;
  try {
    data = JSON.parse(jsonText);
  } catch (e) {
    logVerbose('json parse error', e.message);
    return null;
  }
  const votd = data && data.votd;
  if (!votd) {
    logVerbose('missing votd');
    return null;
  }
  const ref = normalizeSpace(decodeHtmlEntities(stripTags(votd.display_ref || votd.reference || '')));
  const textRaw = votd.text || votd.content || '';
  const text = normalizeSpace(decodeHtmlEntities(stripTags(textRaw)));
  logVerbose('ref', ref);
  logVerbose('text length', text.length);
  if (ref && text) return `${ref} — ${text}`;
  if (text) return text;
  if (ref) return ref;
  return null;
}

function fetchVotd() {
  return new Promise((resolve, reject) => {
    const req = https.get(VOTD_URL, (res) => {
      if (res.statusCode !== 200) {
        res.resume();
        reject(new Error(`HTTP ${res.statusCode}`));
        return;
      }
      let data = '';
      res.setEncoding('utf8');
      res.on('data', (chunk) => (data += chunk));
      res.on('end', () => resolve(data));
    });
    req.on('error', reject);
    req.setTimeout(TIMEOUT_MS, () => {
      req.destroy(new Error('timeout'));
    });
  });
}

async function getVerse() {
  try {
    const body = await fetchVotd();
    const parsed = parseJson(body);
    if (parsed) return parsed;
    logVerbose('parseJson returned null');
  } catch (_) {
    logVerbose('fetch error, using fallback');
    // ignore and fallback
  }
  return fallbackLocal();
}

if (require.main === module) {
  getVerse()
    .then((v) => {
      const output = String(v);
      process.stdout.write(NO_NEWLINE ? output : `${output}\n`);
    })
    .catch(() => {
      const output = fallbackLocal();
      process.stdout.write(NO_NEWLINE ? output : `${output}\n`);
    });
} else {
  module.exports = { getVerse };
}
