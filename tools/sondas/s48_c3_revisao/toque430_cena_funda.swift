final class X {
    func testT430Funda() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
        window.MINI3OFF=1;PR.setupDone=1;window.toast=function(){};var R={},e0=__errs.length,W=function(t){return new Promise(function(r){setTimeout(r,t)})};
        var T=function(n){var r=null;CATS.forEach(function(c){(c.it||[]).forEach(function(it){if(!r&&!it.act&&it.n===n)r=it})});return JSON.parse(JSON.stringify(r))};
        var res=[],BL={};
        for(var wi=0;wi<4;wi++){var WW=[3000,4000,4600,6000][wi];for(var di=0;di<4;di++){var LX=[0,2000,3500,5000][di];
          loadState(initLimpo());S.env='cozinha';S.room='cozinha';S.W=WW;S.H=2700;draw();newTpl(T('Guarda-roupa 2 vãos'));var m=S.mods[0];m.x=WW-m.w-50;
          if(LX){newTpl(T('Balcão 2 portas'));var b=S.mods[1];b.wing=2;b.x=LX;}S.m=null;draw();PLV=true;draw();await W(120);
          var g=document.querySelector('#svg [data-pm="0"]'),gr=g?g.getBoundingClientRect():null,tot=0,ok=0;
          if(gr){for(var fx=.05;fx<1;fx+=.1)for(var fy=.05;fy<1;fy+=.1){var x=gr.left+gr.width*fx,y=gr.top+gr.height*fy;if(y<0||x<0||x>innerWidth||y>innerHeight)continue;tot++;var el=document.elementFromPoint(x,y);if(el&&el.closest&&el.closest('[data-pm="0"]'))ok++;else{var nm=el?(el.id||(el.closest('[id]')||{}).id||el.tagName):'nada';BL[nm]=(BL[nm]||0)+1}}}
          res.push('W'+WW+' wing'+(LX||'-')+' rD'+(typeof roomD==='function'?roomD():'?')+': '+(gr?ok+'/'+tot+' top'+Math.round(gr.top)+' h'+Math.round(gr.height):'sem'));PLV=false;draw()}}
        R.res=res.join(' | ');R.bl=JSON.stringify(BL);R.errs=__errs.length-e0;return JSON.stringify(R);
        """#)
        XCTAssertEqual(o["errs"] as? Int, 0)
    }
}
