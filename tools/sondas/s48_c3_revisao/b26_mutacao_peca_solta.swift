final class X {
    func testB26MutTampo10() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
        window.MINI3OFF=1;PR.setupDone=1;window.toast=function(){};var W=function(t){return new Promise(function(r){setTimeout(r,t)})},e0=__errs.length;
        var mods=[];CATS.forEach(function(c){(c.it||[]).forEach(function(it){var t=typeof it==='number'?TPL[it]:it;if(t&&!t.act&&t.n&&mods.every(function(q){return q.n!==t.n}))mods.push(t)})});
        open3D();await W(400);var out=[],tot=0,tol=1.5,toca=function(a,b){return Math.min(a.x1,b.x1)-Math.max(a.x0,b.x0)>-tol&&Math.min(a.y1,b.y1)-Math.max(a.y0,b.y0)>-tol&&Math.min(a.z1,b.z1)-Math.max(a.z0,b.z0)>-tol};
        mods=mods.slice(0,25);for(var i=0;i<mods.length;i++){var t=JSON.parse(JSON.stringify(mods[i]));loadState(initLimpo());S.env='cozinha';S.room='cozinha';S.W=6000;S.H=2700;draw();newTpl(t);var m=S.mods[0];if(!m)continue;m.x=1500;draw();__build();
          var nc_={};partsOf(m).forEach(function(q){if(q.noCut)nc_[q.name]=(nc_[q.name]||0)+1;else nc_[q.name]=-1e9});
          var B=__boxes().filter(function(b){var pn_=String(b.nm).replace(/^\d+:/,'').replace(/#\d+$/,'');return b.nm&&/^0:/.test(b.nm)&&!(nc_[pn_]>0)&&!b.ft&&b.g!=='sh'&&b.g!=='lo'&&(b.x1-b.x0)>0.2&&(b.y1-b.y0)>0.2&&(b.z1-b.z0)>0.2});tot+=B.length;var mx_=0;B.forEach(function(b){if(/Tampo/.test(b.nm)&&!mx_){mx_=1;b={};}});B.forEach(function(b){if(/Tampo/.test(b.nm)){window.__mt=(window.__mt||0)+1;window.__nms=(window.__nms||'')+b.nm+';';b.z0+=1000;b.z1+=1000;}});
          var ap=B.map(function(b){return b.y0<=tol||b.z0<=tol}),mud=true;while(mud){mud=false;for(var a=0;a<B.length;a++){if(ap[a])continue;for(var c=0;c<B.length;c++){if(ap[c]&&toca(B[a],B[c])){ap[a]=true;mud=true;break}}}}
          var fl=B.filter(function(b,k){return !ap[k]});if(fl.length)out.push(t.n+': '+fl.slice(0,3).map(function(b){return String(b.nm).split(':')[1]}).join(', '))}
        document.getElementById('v3x').click();return JSON.stringify({modelos:mods.length,caixas:tot,soltas:out.join(' | ')||'nenhuma',mt:window.__mt,nms:String(window.__nms).slice(0,300),ex:(function(){loadState(initLimpo());newTpl(JSON.parse(JSON.stringify(mods[0])));__build();return __boxes().filter(function(b){return /^0:/.test(b.nm)}).map(function(b){return b.nm+'['+[b.x0,b.x1,b.y0,b.y1,b.z0,b.z1].map(Math.round)+']'}).slice(0,30).join(' ')})(),errs:__errs.length-e0});
        """#)
        XCTAssertGreaterThan(o["modelos"] as? Int ?? 0, 100, "o catálogo inteiro")
        XCTAssertEqual(o["soltas"] as? String, "nenhuma", "peça de fabricação solta no 3D")
        XCTAssertEqual(o["errs"] as? Int, 0)
    }

    func testB26MutPrat10() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
        window.MINI3OFF=1;PR.setupDone=1;window.toast=function(){};var W=function(t){return new Promise(function(r){setTimeout(r,t)})},e0=__errs.length;
        var mods=[];CATS.forEach(function(c){(c.it||[]).forEach(function(it){var t=typeof it==='number'?TPL[it]:it;if(t&&!t.act&&t.n&&mods.every(function(q){return q.n!==t.n}))mods.push(t)})});
        open3D();await W(400);var out=[],tot=0,tol=1.5,toca=function(a,b){return Math.min(a.x1,b.x1)-Math.max(a.x0,b.x0)>-tol&&Math.min(a.y1,b.y1)-Math.max(a.y0,b.y0)>-tol&&Math.min(a.z1,b.z1)-Math.max(a.z0,b.z0)>-tol};
        mods=mods.slice(0,25);for(var i=0;i<mods.length;i++){var t=JSON.parse(JSON.stringify(mods[i]));loadState(initLimpo());S.env='cozinha';S.room='cozinha';S.W=6000;S.H=2700;draw();newTpl(t);var m=S.mods[0];if(!m)continue;m.x=1500;draw();__build();
          var nc_={};partsOf(m).forEach(function(q){if(q.noCut)nc_[q.name]=(nc_[q.name]||0)+1;else nc_[q.name]=-1e9});
          var B=__boxes().filter(function(b){var pn_=String(b.nm).replace(/^\d+:/,'').replace(/#\d+$/,'');return b.nm&&/^0:/.test(b.nm)&&!(nc_[pn_]>0)&&!b.ft&&b.g!=='sh'&&b.g!=='lo'&&(b.x1-b.x0)>0.2&&(b.y1-b.y0)>0.2&&(b.z1-b.z0)>0.2});tot+=B.length;var mx_=0;B.forEach(function(b){if(/Prateleira/.test(b.nm)&&!mx_){mx_=1;b={};}});B.forEach(function(b){if(/Prateleira/.test(b.nm)){window.__mt=(window.__mt||0)+1;b.z0+=1000;b.z1+=1000;}});
          var ap=B.map(function(b){return b.y0<=tol||b.z0<=tol}),mud=true;while(mud){mud=false;for(var a=0;a<B.length;a++){if(ap[a])continue;for(var c=0;c<B.length;c++){if(ap[c]&&toca(B[a],B[c])){ap[a]=true;mud=true;break}}}}
          var fl=B.filter(function(b,k){return !ap[k]});if(fl.length)out.push(t.n+': '+fl.slice(0,3).map(function(b){return String(b.nm).split(':')[1]}).join(', '))}
        document.getElementById('v3x').click();return JSON.stringify({modelos:mods.length,caixas:tot,soltas:out.join(' | ')||'nenhuma',mt:window.__mt,nms:String(window.__nms).slice(0,300),ex:(function(){loadState(initLimpo());newTpl(JSON.parse(JSON.stringify(mods[0])));__build();return __boxes().filter(function(b){return /^0:/.test(b.nm)}).map(function(b){return b.nm+'['+[b.x0,b.x1,b.y0,b.y1,b.z0,b.z1].map(Math.round)+']'}).slice(0,30).join(' ')})(),errs:__errs.length-e0});
        """#)
        XCTAssertGreaterThan(o["modelos"] as? Int ?? 0, 100, "o catálogo inteiro")
        XCTAssertEqual(o["soltas"] as? String, "nenhuma", "peça de fabricação solta no 3D")
        XCTAssertEqual(o["errs"] as? Int, 0)
    }

}
