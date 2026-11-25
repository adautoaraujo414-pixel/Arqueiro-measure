final class X {
    func testFxxNovoLigada() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
        var W=function(ms){return new Promise(function(r){setTimeout(r,ms)})};window.MINI3OFF=1;PR.setupDone=1;window.toast=function(){};var R={},e0=__errs.length;
        loadState(initLimpo());S.env='cozinha';S.room='cozinha';S.W=4600;S.H=2600;S.fr=[];draw();var a=espWallAdd(4);a.x=150;draw();R.led=JSON.stringify(a.led||null);var med=JSON.stringify([a.x,a.b,a.w,a.h,a.d]);open3D();await W(500);document.querySelectorAll('button').forEach(function(x){if(x.textContent.trim()==='Entendi')x.click()});
        var cv=document.getElementById('cv3'),gl=cv.getContext('webgl'),cx=a.x+a.w/2,cy=a.b+a.h/2,rr=a.w/2-60;
        var faixa=function(){var r=Math.min(2,window.devicePixelRatio||1),H=gl.drawingBufferHeight,px=new Uint8Array(4),n=0;for(var k=0;k<24;k++){var t=Math.PI*2*k/24,p=__p3(cx+rr*Math.cos(t),cy+rr*Math.sin(t),4.2);/* 25/11: na tela pequena (430) a faixa de 40 mm tem 2 a 3 px e o ponto projetado (arredondado) cai a 1 px dela, pra dentro ou pra fora; conta o ponto e os vizinhos a 1 px (o arredondamento da projeção). A faixa atrás do vidro (o defeito ESP-FAIXA) continua sem nenhum aceso */var X=Math.round(p[0]*r),Y=Math.round(H-p[1]*r),ac=0;for(var dx=-1;dx<=1&&!ac;dx++)for(var dy=-1;dy<=1&&!ac;dy++){gl.readPixels(X+dx,Y+dy,1,1,gl.RGBA,gl.UNSIGNED_BYTE,px);if(px[0]>=235&&px[0]-px[2]>=12)ac=1}if(ac)n++}return n};
        var piores=[];for(var ni=0;ni<2;ni++){fx3api.night(ni);['auto','equil','alta'].forEach(function(q){window.ESPQ=q;var m=24;[[1.05,-.5],[1.05,.5],[1.3,-.5],[1.05,0]].forEach(function(z){__cam(z[1],.12,z[0]);m=Math.min(m,faixa())});piores.push(m)})}R.lista=JSON.stringify(piores);
        window.ESPQ='';fx3api.night(0);R.pior=Math.min.apply(null,piores);R.medidas=med===JSON.stringify([a.x,a.b,a.w,a.h,a.d]);document.getElementById('v3x').click();R.errs=__errs.length-e0;return JSON.stringify(R);
        """#)
        XCTAssertGreaterThanOrEqual(o["pior"] as? Int ?? 0, 20, "faixa acesa (de 24 pontos) no pior caso: de longe, em ângulo, dia e noite, auto/equil/alta")
        XCTAssertEqual(o["medidas"] as? Bool, true, "espelho no mesmo lugar e com a mesma medida")
        XCTAssertEqual(o["errs"] as? Int, 0)
    }

    func testFxxNovoDesligada() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
        var W=function(ms){return new Promise(function(r){setTimeout(r,ms)})};window.MINI3OFF=1;PR.setupDone=1;window.toast=function(){};var R={},e0=__errs.length;
        loadState(initLimpo());S.env='cozinha';S.room='cozinha';S.W=4600;S.H=2600;S.fr=[];draw();var a=espWallAdd(4);a.x=150;if(a.led)a.led.on=0;else a.led={on:0};draw();draw();R.led=JSON.stringify(a.led||null);var med=JSON.stringify([a.x,a.b,a.w,a.h,a.d]);open3D();await W(500);document.querySelectorAll('button').forEach(function(x){if(x.textContent.trim()==='Entendi')x.click()});
        var cv=document.getElementById('cv3'),gl=cv.getContext('webgl'),cx=a.x+a.w/2,cy=a.b+a.h/2,rr=a.w/2-60;
        var faixa=function(){var r=Math.min(2,window.devicePixelRatio||1),H=gl.drawingBufferHeight,px=new Uint8Array(4),n=0;for(var k=0;k<24;k++){var t=Math.PI*2*k/24,p=__p3(cx+rr*Math.cos(t),cy+rr*Math.sin(t),4.2);/* 25/11: na tela pequena (430) a faixa de 40 mm tem 2 a 3 px e o ponto projetado (arredondado) cai a 1 px dela, pra dentro ou pra fora; conta o ponto e os vizinhos a 1 px (o arredondamento da projeção). A faixa atrás do vidro (o defeito ESP-FAIXA) continua sem nenhum aceso */var X=Math.round(p[0]*r),Y=Math.round(H-p[1]*r),ac=0;for(var dx=-1;dx<=1&&!ac;dx++)for(var dy=-1;dy<=1&&!ac;dy++){gl.readPixels(X+dx,Y+dy,1,1,gl.RGBA,gl.UNSIGNED_BYTE,px);if(px[0]>=235&&px[0]-px[2]>=12)ac=1}if(ac)n++}return n};
        var piores=[];for(var ni=0;ni<2;ni++){fx3api.night(ni);['auto','equil','alta'].forEach(function(q){window.ESPQ=q;var m=24;[[1.05,-.5],[1.05,.5],[1.3,-.5],[1.05,0]].forEach(function(z){__cam(z[1],.12,z[0]);m=Math.min(m,faixa())});piores.push(m)})}R.lista=JSON.stringify(piores);
        window.ESPQ='';fx3api.night(0);R.pior=Math.min.apply(null,piores);R.medidas=med===JSON.stringify([a.x,a.b,a.w,a.h,a.d]);document.getElementById('v3x').click();R.errs=__errs.length-e0;return JSON.stringify(R);
        """#)
        XCTAssertGreaterThanOrEqual(o["pior"] as? Int ?? 0, 20, "faixa acesa (de 24 pontos) no pior caso: de longe, em ângulo, dia e noite, auto/equil/alta")
        XCTAssertEqual(o["medidas"] as? Bool, true, "espelho no mesmo lugar e com a mesma medida")
        XCTAssertEqual(o["errs"] as? Int, 0)
    }

    func testFxxAntigoLigada() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
        var W=function(ms){return new Promise(function(r){setTimeout(r,ms)})};window.MINI3OFF=1;PR.setupDone=1;window.toast=function(){};var R={},e0=__errs.length;
        loadState(initLimpo());S.env='cozinha';S.room='cozinha';S.W=4600;S.H=2600;S.fr=[];draw();var a=espWallAdd(4);a.x=150;draw();R.led=JSON.stringify(a.led||null);var med=JSON.stringify([a.x,a.b,a.w,a.h,a.d]);open3D();await W(500);document.querySelectorAll('button').forEach(function(x){if(x.textContent.trim()==='Entendi')x.click()});
        var cv=document.getElementById('cv3'),gl=cv.getContext('webgl'),cx=a.x+a.w/2,cy=a.b+a.h/2,rr=a.w/2-60;
        var faixa=function(){var r=Math.min(2,window.devicePixelRatio||1),H=gl.drawingBufferHeight,px=new Uint8Array(4),n=0;for(var k=0;k<24;k++){var t=Math.PI*2*k/24,p=__p3(cx+rr*Math.cos(t),cy+rr*Math.sin(t),4.2);gl.readPixels(Math.round(p[0]*r),Math.round(H-p[1]*r),1,1,gl.RGBA,gl.UNSIGNED_BYTE,px);if(px[0]>=235&&px[0]-px[2]>=12)n++}return n};
        var piores=[];for(var ni=0;ni<2;ni++){fx3api.night(ni);['auto','equil','alta'].forEach(function(q){window.ESPQ=q;var m=24;[[1.05,-.5],[1.05,.5],[1.3,-.5],[1.05,0]].forEach(function(z){__cam(z[1],.12,z[0]);m=Math.min(m,faixa())});piores.push(m)})}R.lista=JSON.stringify(piores);
        window.ESPQ='';fx3api.night(0);R.pior=Math.min.apply(null,piores);R.medidas=med===JSON.stringify([a.x,a.b,a.w,a.h,a.d]);document.getElementById('v3x').click();R.errs=__errs.length-e0;return JSON.stringify(R);
        """#)
        XCTAssertGreaterThanOrEqual(o["pior"] as? Int ?? 0, 20, "faixa acesa (de 24 pontos) no pior caso: de longe, em ângulo, dia e noite, auto/equil/alta")
        XCTAssertEqual(o["medidas"] as? Bool, true, "espelho no mesmo lugar e com a mesma medida")
        XCTAssertEqual(o["errs"] as? Int, 0)
    }

    func testFxxAntigoDesligada() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
        var W=function(ms){return new Promise(function(r){setTimeout(r,ms)})};window.MINI3OFF=1;PR.setupDone=1;window.toast=function(){};var R={},e0=__errs.length;
        loadState(initLimpo());S.env='cozinha';S.room='cozinha';S.W=4600;S.H=2600;S.fr=[];draw();var a=espWallAdd(4);a.x=150;if(a.led)a.led.on=0;else a.led={on:0};draw();draw();R.led=JSON.stringify(a.led||null);var med=JSON.stringify([a.x,a.b,a.w,a.h,a.d]);open3D();await W(500);document.querySelectorAll('button').forEach(function(x){if(x.textContent.trim()==='Entendi')x.click()});
        var cv=document.getElementById('cv3'),gl=cv.getContext('webgl'),cx=a.x+a.w/2,cy=a.b+a.h/2,rr=a.w/2-60;
        var faixa=function(){var r=Math.min(2,window.devicePixelRatio||1),H=gl.drawingBufferHeight,px=new Uint8Array(4),n=0;for(var k=0;k<24;k++){var t=Math.PI*2*k/24,p=__p3(cx+rr*Math.cos(t),cy+rr*Math.sin(t),4.2);gl.readPixels(Math.round(p[0]*r),Math.round(H-p[1]*r),1,1,gl.RGBA,gl.UNSIGNED_BYTE,px);if(px[0]>=235&&px[0]-px[2]>=12)n++}return n};
        var piores=[];for(var ni=0;ni<2;ni++){fx3api.night(ni);['auto','equil','alta'].forEach(function(q){window.ESPQ=q;var m=24;[[1.05,-.5],[1.05,.5],[1.3,-.5],[1.05,0]].forEach(function(z){__cam(z[1],.12,z[0]);m=Math.min(m,faixa())});piores.push(m)})}R.lista=JSON.stringify(piores);
        window.ESPQ='';fx3api.night(0);R.pior=Math.min.apply(null,piores);R.medidas=med===JSON.stringify([a.x,a.b,a.w,a.h,a.d]);document.getElementById('v3x').click();R.errs=__errs.length-e0;return JSON.stringify(R);
        """#)
        XCTAssertGreaterThanOrEqual(o["pior"] as? Int ?? 0, 20, "faixa acesa (de 24 pontos) no pior caso: de longe, em ângulo, dia e noite, auto/equil/alta")
        XCTAssertEqual(o["medidas"] as? Bool, true, "espelho no mesmo lugar e com a mesma medida")
        XCTAssertEqual(o["errs"] as? Int, 0)
    }

}
