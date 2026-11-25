          window.MINI3OFF=1;PR.setupDone=1;var o={},W=function(ms){return new Promise(function(r){setTimeout(r,ms)})};
          var T=function(n){var it=null;CATS.forEach(function(c){c.it.forEach(function(q){var t=typeof q==='number'?TPL[q]:q;if(!it&&t&&t.n===n)it=t})});return JSON.parse(JSON.stringify(it))};
          var folha=function(mi,pk){return __boxes().filter(function(b){return String(b.nm)===mi+':Porta'&&(!pk||b.pk===pk)&&b.a>=.95&&!b.nol}).sort(function(a,b){return (b.y1-b.y0)-(a.y1-a.y0)})[0]};
          var cava=function(mi){var c=__boxes().filter(function(b){return String(b.nm)===mi+':Porta'&&b.nol})[0];return c?Math.round(c.y1-c.y0)+'mm '+JSON.stringify(c.c):'sem'};
          /* 1. canto em L novo ao lado do balcão reto: portas com a mesma regra vertical (cobre a travessa, cava, sobe 5) */
          S.mods=[];S.stones=[];S.W=4000;mkCorner('e');newTpl(T('Balcão 2 portas'));S.mods[1].x=1700;draw();__build();
          var cP=partsOf(S.mods[0]).filter(function(p){return p.name==='Porta'}),rP=partsOf(S.mods[1]).filter(function(p){return p.name==='Porta'});
          o.alturaCorte=cP.map(function(p){return p.cw}).join(',')+' = '+rP[0].cw;
          var fc=folha(0),fr=folha(1);o.topoBase3D=Math.round(fc.y0)+'..'+Math.round(fc.y1)+' = '+Math.round(fr.y0)+'..'+Math.round(fr.y1);
          o.larguraPropria=cP.map(function(p){return p.cl}).join(',');
          o.cava=cava(0)+' = '+cava(1);
          /* 2. textura e veio iguais ao reto (mesmo material) */
          var pf=MAT.filter(function(c){return /pau ferro/i.test(c.n)})[0];S.mods.forEach(function(m){m.corF=pf.hex;m.corFId=pf.id;m.corFN=matLabel(pf)});draw();__build();o.textura=__matTx(folha(0))+' = '+__matTx(folha(1));
          /* 3. canto cego: o painel fixo alinhado com a porta do lado, sem mudar a medida de corte */
          S.mods=[];newTpl(T('Balcão canto cego · cego na direita (porta na esquerda)'));draw();__build();var cg=S.mods[0],cgP=partsOf(cg).filter(function(p){return p.name==='Porta'});
          var pa=folha(0,cgP[0].pk),pc=folha(0,cgP[1].pk);o.cegoAlinhado=Math.round(pa.y0)+'..'+Math.round(pa.y1)+' = '+Math.round(pc.y0)+'..'+Math.round(pc.y1);o.cegoCorte=cgP.map(function(p){return p.cl+'x'+p.cw}).join(',');
          /* 4. painel fixo sem furo de dobradiça (todo o catálogo); porta de verdade continua com o furo */
          var ruins=[],comFuro=0,vistos={};CATS.forEach(function(c){c.it.forEach(function(q){var t=typeof q==='number'?TPL[q]:q;if(!t||t.act||vistos[t.n])return;vistos[t.n]=1;try{S.mods=[];newTpl(JSON.parse(JSON.stringify(t)));var m=S.mods[S.mods.length-1];partsOf(m).forEach(function(p){if(!/^Porta/.test(p.name))return;var fixo=p.cego||(m.v&&m.v[p.vi]&&m.v[p.vi].fixa);var furo=/FURO DE DOBRADIÇA/.test(p.note||'')||!!p.fur;if(fixo&&furo)ruins.push(t.n);if(!fixo&&furo)comFuro++})}catch(_){}})});
          o.fixoSemFuro=ruins.length;o.portaComFuro=comFuro>0;
          /* 5. projeto antigo com canto em L: medida preservada ao abrir; "Atualizar portas do canto" mostra a diferença e só muda com confirmação */
          S.mods=[];mkCorner('e');draw();var st=JSON.parse(JSON.stringify(snapState()));delete st.mods[0].cnv;st.mods[0].cnv=undefined;var antigo=JSON.parse(JSON.stringify(st));
          loadState(antigo);draw();var ma=S.mods[0];o.antigoPreservado=partsOf(ma).filter(function(p){return p.name==='Porta'}).map(function(p){return p.cw}).join(',');
          S.m=ma;S.tab=0;panel();var bt=document.querySelector('#bd [data-cnup]');o.oferece=bt?(document.querySelector('#bd [data-cnupinfo]')||{}).textContent||'':'nao';
          if(bt){bt.click();await W(80)}o.depoisDeConfirmar=partsOf(S.mods[0]).filter(function(p){return p.name==='Porta'}).map(function(p){return p.cw}).join(',');
          /* 6. salva e reabre igual */
          var s1=JSON.stringify(partsOf(S.mods[0]).map(function(p){return p.name+p.cl+'x'+p.cw}));loadState(JSON.parse(JSON.stringify(snapState())));draw();o.reabre=JSON.stringify(partsOf(S.mods[0]).map(function(p){return p.name+p.cl+'x'+p.cw}))===s1;
          o.errs=__errs;return JSON.stringify(o);
