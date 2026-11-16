var W=function(ms){return new Promise(function(r){setTimeout(r,ms)})};await W(2500);
var ls=JSON.parse(localStorage.getItem('arque.projects.v1')||'null');var f=__files['projects.json'];var fd=f?JSON.parse(decodeURIComponent(escape(atob(f)))):null;
return JSON.stringify({localStorage_projetos:ls?ls.length:null,arquivo_projetos:fd?fd.length:null,listaNoApp:pLoadAll().length});
