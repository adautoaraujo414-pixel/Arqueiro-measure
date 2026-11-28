
/* cada teste começa sem nada guardado do teste anterior (ao sair da página o editor grava o que estava pendente) */
try{localStorage.clear();sessionStorage.clear()}catch(e){}
window.__noSetup=1;window.__errs=[];
window.addEventListener('error',function(e){__errs.push(String(e.message||e))});
window.addEventListener('unhandledrejection',function(e){__errs.push('promise: '+String(e.reason))});
window.__files={};window.__shared=null;
(function(){var A={isApp:function(){return true},isWindows:function(){return true},isViewer:function(){return false},isSharing:function(){return false},setCurrent:function(){},
  putFile:function(n,b){__files[n]=b},getFile:function(n){return __files[n]||''},delFile:function(n){delete __files[n]},
  listFiles:function(){return JSON.stringify(Object.keys(__files))},companyName:function(){return 'Marcenaria Teste'},
  shareCut:function(c,n,t){__shared={code:c,name:n,title:t}},shareClient:function(c,n,t){window.__sharedCl={code:c,name:n,title:t}},listNotes:function(){return '[]'},
  contextNote:function(){return ''},linkNote:function(){},openNoteOf:function(){},shareUpdate:function(){},shareStart:function(){},
  makeQuote:function(){},quotePhotos:function(){},openTrena:function(){},tourResult:function(){},close:function(){window.__closed=(window.__closed||0)+1},
  /* igual à ponte do app do Windows (Browser.kt): CSV e DXF saem pelo shareFile, nunca por download do navegador (o JCEF do app de teste caía às vezes no download de blob) */
  shareFile:function(n,t,m){window.__sharedFile={name:n,len:String(t||'').length,mime:m}}};
  /* a ponte de verdade do app (que grava em arquivo) é posta depois: aqui ela é ignorada, os testes ficam só na memória */
  try{Object.defineProperty(window,'ArqueApp',{configurable:true,get:function(){return A},set:function(){}})}catch(e){window.ArqueApp=A}})();
