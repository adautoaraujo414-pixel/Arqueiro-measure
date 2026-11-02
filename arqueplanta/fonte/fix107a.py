import sys
SP='/tmp/claude-0/-home-claude/6d33c1b2-7925-5f03-890b-726a52a5fe54/scratchpad/'
P='/home/claude/arqueiro-measure-gh/app/src/main/assets/editor.html'
src=open(P,encoding='utf-8').read()
def rep(old,new,cnt=1):
    global src
    n=src.count(old)
    if n!=cnt: print('COUNT',n,'!=',cnt,'for',old[:160]);sys.exit(1)
    src=src.replace(old,new)
G=''.join(open(SP+'isl/'+f,encoding='utf-8').read().strip()+'\n' for f in ['glob7.js','glob8.js','glob9.js'])
V3G=open(SP+'isl/v3g.js',encoding='utf-8').read().strip()
rep("function sideWalls0(){",G+"function sideWalls0(){")
rep("window.isl3api={",V3G+"\nwindow.isl3api={")
# 3D: faces da casa (cor e textura por face), sem o desenho sem WebGL
rep("  if(b.gq){if(window.gqFill)window.gqFill(b,V);return}","  if(b.hq){if(window.hqFill)window.hqFill(b,V,LL);return}\n  if(b.gq){if(window.gqFill)window.gqFill(b,V);return}")
rep("bg.filter(wvis).forEach(function(b){add(bgf,b)});","bg.filter(function(b){return wvis(b)&&!b.hq}).forEach(function(b){add(bgf,b)});")
# câmera mira no meio da casa (ext.cx/cz) e anda dentro dela (WALK3)
rep("var tx=ext.x/2,ty=ext.y/2.4,tz=ext.z/2,","var tx=ext.cx!=null?ext.cx:ext.x/2,ty=ext.y/2.4,tz=ext.cz!=null?ext.cz:ext.z/2,",2)
rep(" var W4=[-R3[0],-R3[1],-R3[2],dist+dt(R3)];"," var W4=[-R3[0],-R3[1],-R3[2],dist+dt(R3)];\n if(window.WALK3){var WK_=window.WALK3;F=Math.min(w,h)*.85*zoom;n=60;f=80000;A=(f+n)/(f-n);Bz=2*f*n/(f-n);tx=WK_.x;ty=WK_.y;tz=WK_.z;W4=[-R3[0],-R3[1],-R3[2],dt(R3)]}")
rep("['r0','r1','r2','r3'].forEach(function(nm,i){gl.uniform4fv(gl.getUniformLocation(GP,nm),[X,Y,Z,W4][i])});","['r0','r1','r2','r3'].forEach(function(nm,i){gl.uniform4fv(gl.getUniformLocation(GP,nm),[X,Y,Z,W4][i])});gl.uniform1f(gl.getUniformLocation(GP,'pk'),1/F);")
# texturas da casa no shader (tijolo, bloco, chapisco, reboco, massa, pintura, revestimentos, pisos, telha)
i=src.find(" var vs='attribute vec3 p;");j=src.find("';",src.find(" fs='precision mediump float;",i))+2
assert i>0 and j>i
old=src[i:j]
assert "if(vt>3.5){float l=texture2D(tx,uv).r;col=vc.rgb*(.93+l*.24);}else if(vt>2.5){float l=texture2D(tx2,uv*.5).r;col=mix(vc.rgb,vec3(.9,.9,.88),(1.-l)*.9);}else if(vt>1.5){float l=texture2D(tx2,uv*.5).r;col=vc.rgb*(.5+.5*l);}else if(vt>.5){float l=texture2D(tx,uv).r;col=vc.rgb*(.7+l*1.7);}" in old
VS="attribute vec3 p;attribute vec4 c;attribute float t;uniform vec4 r0,r1,r2,r3;varying vec4 vc;varying vec2 uv;varying float vt;varying float vk;varying vec2 vq;varying float vw;void main(){vec4 q=vec4(p,1.);gl_Position=vec4(dot(r0,q),dot(r1,q),dot(r2,q),dot(r3,q));vc=c;vt=t;uv=vec2(p.x+p.y*.37,p.z+p.y*.61)/420.;vk=0.;vq=vec2(0.);vw=gl_Position.w;if(t>9999.){float k=floor((t-10000.)/400.+.0001);float a=t-10000.-k*400.;vk=k;vt=0.;if(a>398.5){vq=p.xz/1000.;}else{float an=radians(a);vq=vec2(p.x*cos(an)+p.z*sin(an),p.y)/1000.;}}}"
FS=("#ifdef GL_FRAGMENT_PRECISION_HIGH\\nprecision highp float;\\n#else\\nprecision mediump float;\\n#endif\\n"
 "uniform sampler2D tx;uniform sampler2D tx2;uniform float pk;varying vec4 vc;varying vec2 uv;varying float vt;varying float vk;varying vec2 vq;varying float vw;"
 "float h21(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}"
 "float vn(vec2 p){vec2 i=floor(p);vec2 f=fract(p);f=f*f*(3.-2.*f);return mix(mix(h21(i),h21(i+vec2(1.,0.)),f.x),mix(h21(i+vec2(0.,1.)),h21(i+vec2(1.,1.)),f.x),f.y);}"
 "vec2 grd(vec2 q,vec2 c,float j,float b,float px){float r=floor(q.y/c.y);float x=q.x+b*r*c.x;vec2 id=vec2(floor(x/c.x),r);vec2 f=vec2(x-id.x*c.x,q.y-r*c.y);float m=min(min(f.x,c.x-f.x),min(f.y,c.y-f.y));float hw=j*.5;float g=1.-smoothstep(hw-px*.6,hw+px*.6,m);float fd=clamp(1.5-px/(j+.0004),0.,1.);return vec2(g*fd,h21(id));}"
 "vec3 pat(float k,vec2 q,vec3 c,float px){"
 "if(k<3.5||(k>15.5&&k<17.5)){vec2 s=k<1.5?vec2(.21,.065):k<2.5?vec2(.2,.2):k<3.5?vec2(.4,.2):k<16.5?vec2(.2,.15):vec2(.3,.2);vec2 g=grd(q,s,.01,.5,px);vec3 cc=c*(.86+.26*g.y)*(.94+.1*vn(q*60.));return mix(cc,vec3(.7,.68,.63),g.x);}"
 "if(k<4.5){float n=h21(floor(q*170.));return c*(.8+.28*n*clamp(1.-px*150.,0.,1.)+.12*vn(q*25.));}"
 "if(k<5.5)return c*(.93+.08*vn(q*3.)+.04*vn(q*45.));"
 "if(k<6.5)return c*(.975+.035*vn(q*2.5));"
 "if(k<7.5)return c*(.985+.02*vn(q*1.5));"
 "if(k<13.5){vec2 s=k<8.5?vec2(.6,.6):k<9.5?vec2(1.2,.6):k<10.5?vec2(.3,.3):k<11.5?vec2(.45,.45):k<12.5?vec2(.2,.1):vec2(.05,.05);float j=k<9.5?.003:.004;float b=(k>11.5&&k<12.5)?.5:0.;vec2 g=grd(q,s,j,b,px);vec3 cc=c*(.95+.08*g.y+.04*vn(q*8.));if(k>12.5)cc=c*(.8+.4*g.y);return mix(cc,vec3(.86,.85,.82),g.x*.85);}"
 "if(k<14.5){float r=floor(q.y/.06);vec2 g=grd(vec2(q.x+h21(vec2(r,7.))*.3,q.y),vec2(.13+.1*h21(vec2(r,3.)),.06),.005,0.,px);return mix(c*(.75+.5*g.y),c*.5,g.x*.8);}"
 "if(k<20.5)return c*(.88+.14*vn(q*2.)+.06*vn(q*25.));"
 "if(k<22.5){vec2 s=k<21.5?vec2(1.2,.2):vec2(1.2,.18);float r=floor(q.y/s.y);vec2 g=grd(vec2(q.x+h21(vec2(r,1.))*s.x,q.y),s,.003,0.,px);float gr=vn(vec2(q.x*3.,q.y*90.));return mix(c*(.82+.25*g.y)*(.9+.18*gr),c*.55,g.x*.7);}"
 "if(k<23.5)return c*(.9+.14*vn(q*1.2)+.05*vn(q*9.));"
 "if(k<24.5)return c*(.75+.4*vn(q*30.)+.15*vn(q*3.));"
 "if(k<25.5){vec2 g=grd(q,vec2(.4,.4),.008,0.,px);return mix(c*(.85+.25*g.y),c*.6,g.x*.8);}"
 "if(k<26.5){float r=fract(q.y*3.);float s=fract(q.x/.21);return c*(.72+.38*smoothstep(0.,.4,s)*(1.-smoothstep(.6,1.,s)))*(r<.1?.72:1.);}"
 "return c;}"
 "void main(){vec3 col=vc.rgb;if(vt>3.5){float l=texture2D(tx,uv).r;col=vc.rgb*(.93+l*.24);}else if(vt>2.5){float l=texture2D(tx2,uv*.5).r;col=mix(vc.rgb,vec3(.9,.9,.88),(1.-l)*.9);}else if(vt>1.5){float l=texture2D(tx2,uv*.5).r;col=vc.rgb*(.5+.5*l);}else if(vt>.5){float l=texture2D(tx,uv).r;col=vc.rgb*(.7+l*1.7);}if(vk>.5){float px=max(vw*pk,.05)/1000.;col=pat(vk,vq,col,px);}gl_FragColor=vec4(col,vc.a);}")
new=" var vs='"+VS+"',\n fs='"+FS+"';"
src=src[:i]+new+src[j:]
# salvar a casa junto do projeto (e desfazer/refazer)
rep("xw:S.xw||[],geo:S.geo||[]}))}","xw:S.xw||[],geo:S.geo||[],casa:S.casa||null}))}")
rep("S.xw=Array.isArray(o.xw)?o.xw:[];S.geo=Array.isArray(o.geo)?o.geo:[];","S.xw=Array.isArray(o.xw)?o.xw:[];S.geo=Array.isArray(o.geo)?o.geo:[];S.casa=(o.casa&&typeof o.casa==='object')?o.casa:null;CGK='';")
# botão 🏠 Casa na barra do editor
i=src.find('<button id="b3d" class="hb"');j=src.find('</button>',i)+len('</button>')
ICON='<svg viewBox="0 0 32 32" width="24" height="24" aria-hidden="true" class="ico" style="flex:none;width:24px;height:24px;min-width:24px;max-width:none;vertical-align:middle;overflow:visible;display:inline-block;background:none;border:0;margin:0;pointer-events:none"><path d="M4 15L16 5l12 10" fill="none" stroke="#c0392b" stroke-width="2.2" stroke-linejoin="round" stroke-linecap="round"/><path d="M7.5 13v14h17V13" fill="#f3e3c4" stroke="#3a3128" stroke-width="1.4" stroke-linejoin="round"/><path d="M13.5 27v-7h5v7" fill="#a07a52" stroke="#3a3128" stroke-width="1.2" stroke-linejoin="round"/><path d="M9.5 15.5h3.5v3.5H9.5z" fill="#bcd6e6" stroke="#3a3128" stroke-width="1"/><path d="M19 15.5h3.5v3.5H19z" fill="#bcd6e6" stroke="#3a3128" stroke-width="1"/></svg>'
src=src[:j]+'<button id="bcasa" class="hb" title="Planta da casa: 3D, medidas, quantitativos e documentos" aria-label="Planta da casa">'+ICON+'<span>Casa</span></button>'+src[j:]
rep("$('b3d').onclick=function(){open3D()};","$('b3d').onclick=function(){open3D()};$('bcasa').onclick=function(){casaOpen()};")
open(P,'w',encoding='utf-8').write(src)
print('ok 107a')
