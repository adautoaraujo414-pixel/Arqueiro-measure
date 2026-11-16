import fs from 'fs';
const s=fs.readFileSync('/home/claude/arqueiro-measure/app/src/main/assets/editor.html','utf8');
const re=/<script(?![^>]*src=)[^>]*>([\s\S]*?)<\/script>/g;let m,i=0,bad=0;
while((m=re.exec(s))){i++;try{new Function(m[1])}catch(e){bad++;console.log('block',i,'ERR',e.message)}}
console.log('blocks',i,'bad',bad);
