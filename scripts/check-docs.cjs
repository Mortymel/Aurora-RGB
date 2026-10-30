'use strict';
const fs=require('node:fs'),path=require('node:path'),cp=require('node:child_process');
const all=cp.execFileSync('git',['ls-files','-z'],{encoding:'utf8'}).split('\0').filter(Boolean);
const documents=all.filter(p=>p.endsWith('.md'));
const problems=[];let count=0,examples=0;
const headings=text=>new Set([...text.matchAll(/^#{1,6}\s+(.+)$/gm)].map(m=>m[1].toLowerCase().replace(/[^\p{L}\p{N}\s_-]/gu,'').replace(/\s/g,'-')));
for(const file of documents){
 const text=fs.readFileSync(file,'utf8');
 if(!/^#{1,6}\s+/m.test(text))problems.push(file+': missing heading');
 if(text.includes('ESP32-RGB-Studio-'))problems.push(file+': obsolete repository link');
 if(/[\x00-\x08\x0b\x0c\x0e-\x1f]/.test(text))problems.push(file+': control character');
 const prose=text.replace(/^(```|~~~)[^\n]*\n[\s\S]*?^\1\s*$/gm,'');
 for(const match of prose.matchAll(/\]\(([^)]+)\)/g)){
  if(/^(https?:|mailto:)/.test(match[1]))continue;
  count++;const [href,anchor]=match[1].split('#');
  const target=href?path.posix.normalize(path.posix.join(path.posix.dirname(file),href)):file;
  if(target.startsWith('../')||!fs.existsSync(target)){problems.push(file+' -> '+target);continue;}
  if(anchor&&target.endsWith('.md')&&!headings(fs.readFileSync(target,'utf8')).has(decodeURIComponent(anchor)))problems.push(file+': anchor not found '+match[1]);
 }
 for(const match of text.matchAll(/^```json\s*\n([\s\S]*?)^```/gm)){examples++;try{JSON.parse(match[1]);}catch{problems.push(file+': invalid JSON example');}}
 if((text.match(/^```/gm)||[]).length%2||(text.match(/^~~~/gm)||[]).length%2)problems.push(file+': unbalanced fence');
}
if(problems.length){console.error(problems.join('\n'));process.exitCode=1;}else console.log(`${documents.length} documents, ${count} relative links, ${examples} JSON examples: OK`);

