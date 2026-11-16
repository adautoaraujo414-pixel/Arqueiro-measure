window.__SEEDMODE='vazio';
;(function(){var b=function(s){return btoa(unescape(encodeURIComponent(s)))};
var mod={t:'base',w:900,h:820,d:560,x:5,egL:30,egR:30,v:[{k:'door',n:2}]};
var cur={env:'cozinha',W:3600,H:2700,mods:[mod],stones:[],rp:[],fr:[],ops:[]};
var P=[{id:'pA',client:{nome:'Teste A'},created:1000,updated:1000,current:cur,original:cur}];
window.__SEED=P;
if(window.__SEEDMODE==='vazio'){localStorage.setItem('arque.projects.v1',JSON.stringify(P));__files['projects.json']=b('[]')}
else{localStorage.setItem('arque.projects.v1',JSON.stringify(P));__files['projects.json']=b(JSON.stringify(P))}})();
