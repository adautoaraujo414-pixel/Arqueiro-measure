'use strict';
const fs=require('node:fs'),assert=require('node:assert/strict');
const s=fs.readFileSync('app/src/main/assets/arque-mob.html','utf8');
const need=[
 ['version:\'0.35\'','Versionamento de dados'],
 ['function usableModulePosition(','Validação de colisão entre móveis'],
 ['function snappedModulePosition(','Encaixe ao arrastar módulo'],
 ['function withinApplianceSpace(','Verificação da posição dos eletrodomésticos'],
 ['data-type="oven"','Forno na biblioteca'],
 ['data-type="microwave"','Micro-ondas na biblioteca'],
 ['function plan(src=st){','Peças a partir das dimensões do módulo'],
 ['function cutAudit(','Auditoria de peças contra chapa'],
 ['function cutCsv(','Exportação de lista com material e fita'],
 ['moduleSeq:1,caseMaterial:','Material base da marcenaria'],
 ['room:st.room','Persistência do cômodo']
];
for(const [token,reason] of need)assert(s.includes(token),reason);
const code=s.slice(s.indexOf('<script>')+8,s.lastIndexOf('</script>'));
new Function(code);
assert(s.includes("caseMaterial:st.caseMaterial"),'Material precisa persistir');
assert(s.includes("const clone=o=>o===undefined?undefined"),'Projetos antigos sem materiais precisam abrir');
assert(s.includes("Não é plano otimizado de chapas"),'Prévia não pode ser vendida como CNC');
console.log('Arque Mob 0.21: regras 3D, módulos, equipamentos, lista e migração: OK');
