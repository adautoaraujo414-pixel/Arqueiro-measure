final class X {
    func testFxxSonda() async throws {
        let web = try await editor()
        let o = try await run(web, #"""
        var W=function(ms){return new Promise(function(r){setTimeout(r,ms)})};window.MINI3OFF=1;PR.setupDone=1;window.toast=function(){};var R={},e0=__errs.length;
        loadState(initLimpo());S.env='cozinha';S.room='cozinha';S.W=4600;S.H=2600;S.fr=[];draw();var a=espWallAdd(4);a.x=150;draw();open3D();await W(500);document.querySelectorAll('button').forEach(function(x){if(x.textContent.trim()==='Entendi')x.click()});
        var cv=document.getElementById('cv3'),gl=cv.getContext('webgl'),cx=a.x+a.w/2,cy=a.b+a.h/2,rr=a.w/2-60;
        var r=Math.min(2,window.devicePixelRatio||1),H=gl.drawingBufferHeight,Wd=gl.drawingBufferWidth;var FB=new Uint8Array(Wd*H*4);var snap=function(){gl.readPixels(0,0,Wd,H,gl.RGBA,gl.UNSIGNED_BYTE,FB)};var lit=function(X,Y){if(X<0||Y<0||X>=Wd||Y>=H)return false;var i=(Y*Wd+X)*4;return FB[i]>=235&&FB[i]-FB[i+2]>=12};
        var out=[];for(var ni=0;ni<2;ni++){fx3api.night(ni);['auto','equil','alta'].forEach(function(q){window.ESPQ=q;[[1.05,-.5],[1.05,.5],[1.3,-.5],[1.05,0]].forEach(function(z){__cam(z[1],.12,z[0]);snap();
          var c=__p3(cx,cy,4.2),e=__p3(cx+rr,cy,4.2),dist=[],buraco=0,larg=[];
          for(var k=0;k<24;k++){var t=Math.PI*2*k/24,p=__p3(cx+rr*Math.cos(t),cy+rr*Math.sin(t),4.2),X=Math.round(p[0]*r),Y=Math.round(H-p[1]*r),d=99;for(var s=0;s<=4&&d==99;s++)for(var dx=-s;dx<=s;dx++)for(var dy=-s;dy<=s;dy++){if(Math.max(Math.abs(dx),Math.abs(dy))!==s)continue;if(d==99&&lit(X+dx,Y+dy))d=s}dist.push(d)}
          for(var g=0;g<360;g++){var t=Math.PI*2*g/360,ach=0,n=0;for(var u=-100;u<=100;u+=2){var p=__p3(cx+(rr+u)*Math.cos(t),cy+(rr+u)*Math.sin(t),4.2);if(lit(Math.round(p[0]*r),Math.round(H-p[1]*r))){ach=1;n++}}if(!ach)buraco++;larg.push(n)}
          out.push({n:ni,q:q,z:z.join(','),raioPx:Math.round(Math.hypot((e[0]-c[0])*r,(e[1]-c[1])*r)),dist:dist.join(''),buracos360:buraco,amostrasAcesasMin:Math.min.apply(null,larg)})})})}
        /* recorte da tela pra imagem: vista 1,05/-0,5 de dia, equil */
        fx3api.night(0);window.ESPQ='equil';__cam(-.5,.12,1.05);var c=__p3(cx,cy,4.2),X0=Math.max(0,Math.round(c[0]*r)-90),Y0=Math.max(0,Math.round(H-c[1]*r)-90),bw=180,bh=180,buf=new Uint8Array(bw*bh*4);gl.readPixels(X0,Y0,bw,bh,gl.RGBA,gl.UNSIGNED_BYTE,buf);var b64='';for(var i=0;i<buf.length;i+=3000)b64+=String.fromCharCode.apply(null,buf.subarray(i,i+3000));R.img=btoa(b64);R.bw=bw;R.bh=bh;
        window.ESPQ='';R.out=JSON.stringify(out);document.getElementById('v3x').click();R.errs=__errs.length-e0;return JSON.stringify(R);
        """#)
        XCTAssertEqual(o["errs"] as? Int, 0)
    }
}
