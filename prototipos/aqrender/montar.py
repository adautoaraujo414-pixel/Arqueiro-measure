# Monta a CÓPIA ISOLADA do editor com o protótipo AQRender (não mexe no app).
# uso: python3 prototipos/aqrender/montar.py  → gera prototipos/aqrender/editor.html (não versionado)
# Para abrir no navegador, a pasta precisa de "cores" e "i18n" ao lado (links pra app/src/main/assets).
import os
R=os.path.dirname(os.path.abspath(__file__));A=os.path.join(R,'..','..','app','src','main','assets')
s=open(os.path.join(A,'editor.html'),encoding='utf-8').read();aq=open(os.path.join(R,'aq_patch.js'),encoding='utf-8').read()
def rep(a,b,n=1):
    global s
    assert s.count(a)==n,(a[:60],s.count(a));s=s.replace(a,b)
s=s.replace('*sh/255','*(window.AQ?1:sh)/255')
rep("var sh=b.em?1:f[2]","var sh=(b.em||window.AQ)?1:f[2]",2)
a="if(b.g!=='lo'){var tm=b.gl?9:ph?7:(b.g==='st'||b.g==='stc')?(b.tx||txRGB()[b.c.join()]||1):matTx(b);"
rep(a,a+"if(window.AQ&&!tr){if(b.em)tm=11;else if(b.mt||(b.mid&&/^inox/.test(b.mid))||/Dobradi|Puxador|Corrediça|Pé de metal|Trilho|Perfil/.test(String(b.nm||'')))tm=10}")
rep("pxPut(q,col,al);for(var z_=n0_;z_<boxes.length;z_++)boxes[z_].nol=1","pxPut(q,col,al);for(var z_=n0_;z_<boxes.length;z_++){boxes[z_].nol=1;boxes[z_].mt=1}")
rep("mb[id].n=up(mb[id].buf,MV[id])});gDirty=false}","mb[id].n=up(mb[id].buf,MV[id])});if(window.AQ){try{aqUp(F,T,MV)}catch(e){window.AQERR=String(e)}}gDirty=false}")
a="window.PM3={X:X,Y:Y,W:W4,w:w,h:h};"
rep(a,a+"if(window.AQ&&AQP&&AQL){try{window.aqLinhas=function(){gl.useProgram(GP);['r0','r1','r2','r3'].forEach(function(nm,i){gl.uniform4fv(gl.getUniformLocation(GP,nm),[X,Y,Z,W4][i])});var pl=gl.getAttribLocation(GP,'p'),cl=gl.getAttribLocation(GP,'c'),tl=gl.getAttribLocation(GP,'t');[pl,cl,tl].forEach(function(l){gl.enableVertexAttribArray(l)});if(lN){gl.bindBuffer(gl.ARRAY_BUFFER,GB.l);gl.vertexAttribPointer(pl,3,gl.FLOAT,false,32,0);gl.vertexAttribPointer(cl,4,gl.FLOAT,false,32,12);gl.vertexAttribPointer(tl,1,gl.FLOAT,false,32,28);gl.blendColor(0,0,0,.28);gl.blendFunc(gl.CONSTANT_ALPHA,gl.ONE_MINUS_CONSTANT_ALPHA);gl.drawArrays(gl.LINES,0,lN);gl.blendFunc(gl.SRC_ALPHA,gl.ONE_MINUS_SRC_ALPHA)}};aqDraw(X,Y,Z,W4,[tx+dist*R3[0],ty+dist*R3[1],tz+dist*R3[2]]);return}catch(e){window.AQERR=String(e)}}")
a="if(gl)glInit();window.gl3ok=function(){return glOK};"
rep(a,a+"\n"+aq+"\n")
s=s.replace('<title>','<title>PROTÓTIPO AQRender · ',1)
open(os.path.join(R,'editor.html'),'w',encoding='utf-8').write(s);print('ok',len(s))
