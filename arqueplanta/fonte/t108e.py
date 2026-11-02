from playwright.sync_api import sync_playwright
import json
URL='file:///home/claude/arqueiro-measure-gh/app/src/main/assets/editor.html'
SP='/tmp/claude-0/-home-claude/6d33c1b2-7925-5f03-890b-726a52a5fe54/scratchpad/t107/'
ok=[];bad=[];errs=[]
def chk(n,c,i=''):(ok if c else bad).append(n+('' if c else ' '+str(i)))
with sync_playwright() as p:
    b=p.chromium.launch(args=['--use-gl=swiftshader','--enable-webgl','--ignore-gpu-blocklist']);pg=b.new_page(viewport={'width':420,'height':860});ev=pg.evaluate;pg.on('pageerror',lambda e:errs.append(str(e)))
    pg.goto(URL);ev("window.__noSetup=1");pg.wait_for_timeout(300);ev("PR.setupDone=1")
    pg.click('#bcasa');pg.wait_for_timeout(200)
    chk('botão ▭ Cômodo',ev("!!document.querySelector('#casa [data-tool=\"room\"]')"))
    chk('botão 🧊 Criar 3D',ev("!!document.querySelector('#casaTools [data-ct=\"3d\"]')"))
    ev("CU.vb=[-1000,-1000,12000,12000*Math.max(1,document.getElementById('casaV').clientHeight/document.getElementById('casaV').clientWidth)];cuAspect();cuPlan();casaApi.tool('room')")
    def sc(x,z):return json.loads(ev("JSON.stringify((function(){var V=document.getElementById('casaV').getBoundingClientRect(),vb=CU.vb;return [V.left+(%d-vb[0])/vb[2]*V.width,V.top+(%d-vb[1])/vb[3]*V.height]})())"%(x,z)))
    def drag(a,b2):
        A=sc(*a);B=sc(*b2);pg.mouse.move(A[0],A[1]);pg.mouse.down();pg.mouse.move((A[0]+B[0])/2,(A[1]+B[1])/2,steps=4);pg.mouse.move(B[0],B[1],steps=4);pg.mouse.up();pg.wait_for_timeout(150)
    drag((0,0),(4000,3000))
    chk('cômodo = 4 paredes',ev("casa().W.length")==4,ev("casa().W.length"))
    chk('1 ambiente fechado',len(json.loads(ev("JSON.stringify(casaApi.rooms())")))==1)
    ev("casaApi.tool('room')");drag((4000,0),(7000,3000))
    nW=ev("casa().W.length");R=json.loads(ev("JSON.stringify(casaApi.rooms())"))
    chk('segundo cômodo aproveita a parede do meio (sem parede dupla)',nW<=7,nW)
    chk('2 ambientes',len(R)==2,R)
    # parede solta perto: deve juntar
    ev("casaApi.tool('wall')");drag((2000,3000),(2000,5900))
    ev("casaApi.tool('wall')");drag((1800,6000),(5000,6000))
    W=json.loads(ev("JSON.stringify(casa().W.map(function(w){return [w.a,w.b]}))"));print(W)
    ev("var c=casa();c.W.push({id:cId(c.W),a:[7000,3000],b:[7000,5700],t:150});c.W.push({id:cId(c.W),a:[5150,6000],b:[7300,6000],t:150})")
    n=ev("(function(){var r=cJoin(600);return r})()");print('juntou',n)
    pg.click('#casa [data-cu="join"]');pg.wait_for_timeout(100)
    free=ev("(function(){var C=casa(),f=0;C.W.forEach(function(w){['a','b'].forEach(function(e){var p=w[e];if(!C.W.some(function(o){return o!==w&&(Math.hypot(o.a[0]-p[0],o.a[1]-p[1])<=30||Math.hypot(o.b[0]-p[0],o.b[1]-p[1])<=30||pSegD(p,o.a,o.b)<=cT(o)/2+5)}))f++})});return f})()")
    chk('sem pontas soltas depois de juntar',free==0,free)
    R2=json.loads(ev("JSON.stringify(casaApi.rooms())"));print(R2)
    chk('ambientes fechados com as paredes juntadas',len(R2)>=3,R2)
    pg.screenshot(path=SP+'room_tool.png')
    ev("document.querySelector('#casaTools [data-ct=\"3d\"]').click()");pg.wait_for_timeout(400);chk('Criar 3D abre o 3D',ev("c3api.on()")==1)
    b.close()
print('OK',ok);print('FALHOU',bad);print('errs',errs)
