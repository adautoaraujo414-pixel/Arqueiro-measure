from playwright.sync_api import sync_playwright
import json
URL='file:///home/claude/arqueiro-measure-gh/app/src/main/assets/editor.html'
SP='/tmp/claude-0/-home-claude/6d33c1b2-7925-5f03-890b-726a52a5fe54/scratchpad/t107/'
errs=[];ok=[];bad=[]
def chk(n,c):
    (ok if c else bad).append(n)
with sync_playwright() as p:
    b=p.chromium.launch(args=['--use-gl=swiftshader','--enable-webgl','--ignore-gpu-blocklist']);pg=b.new_page(viewport={'width':420,'height':860},accept_downloads=True)
    pg.on('pageerror',lambda e:errs.append(str(e)))
    # ponte falsa do app: nota com 2 cômodos (sala + cozinha) e um PDF compartilhado
    pg.add_init_script("""window.__shared=[];window.ArqueApp={isApp:function(){return true},contextNote:function(){return JSON.stringify({id:'n1',name:'Sra. Ana'})},listNotes:function(){return JSON.stringify([{id:'n1',name:'Sra. Ana',date:'01/11/2026'},{id:'n2',name:'Vazia',date:'01/11/2026'}])},
     noteRooms:function(id){if(id!=='n1')return '';var J={rooms:[{pts:[[100,100],[400,100],[400,300],[100,300]],closed:true,segs:[{k:'WALL',mm:4400},{k:'WALL',mm:2850},{k:'WALL',mm:4400},{k:'WALL',mm:2850}]},{pts:[[400,100],[600,100],[600,300],[400,300]],closed:true,segs:[{k:'WALL',mm:2850},{k:'WALL',mm:2850},{k:'WALL',mm:1000},{k:'DOOR',mm:800,hinge:0,side:1},{k:'WALL',mm:1050},{k:'WALL',mm:2850}]}],doors:[],texts:[{x:250,y:200,t:'Sala · pé-direito 2,70 m'},{x:500,y:200,t:'Cozinha'}]};
      J.rooms[1].pts=[[400,100],[600,100],[600,300],[530,300],[470,300],[400,300]];return JSON.stringify(J)},
     shareFile:function(n,b,m){window.__shared.push([n,b.length,m])},setCurrent:function(){},putFile:function(){},getFile:function(){return ''},listFiles:function(){return '[]'},delFile:function(){},companyName:function(){return 'Marcenaria Araújo'}};""")
    pg.goto(URL);ev=pg.evaluate;ev("window.__noSetup=1");pg.wait_for_timeout(400);ev("try{PR.setupDone=1}catch(e){}")
    pg.click('#bcasa');pg.wait_for_timeout(300)
    # puxar da nota
    ev("document.querySelector('#casa [data-cu=\"imp\"]').click()");pg.wait_for_timeout(150)
    chk('lista de notas',ev("document.querySelectorAll('#casaP [data-imp]').length")>=2)
    ev("document.querySelector('#casaP [data-imp=\"n1\"]').click()");pg.wait_for_timeout(300)
    R=json.loads(ev("JSON.stringify(casaApi.rooms())"));print('import rooms',R)
    chk('importou sala e cozinha',[r['n'] for r in R]==['Sala','Cozinha'] or sorted(r['n'] for r in R)==['Cozinha','Sala'])
    chk('sala 4,40 x 2,85',any(r['n']=='Sala' and abs(r['a']-12.54)<0.05 for r in R))
    chk('porta na cozinha',ev("casa().O.length")==1)
    chk('pé-direito 2,70',ev("casa().cfg.h")==2700)
    ev("document.querySelector('#casaP [data-imp=\"n2\"]')") 
    # desenhar uma parede nova arrastando
    ev("casaApi.tool('wall')");box=pg.locator('#casaV').bounding_box()
    nW=ev("casa().W.length")
    pg.mouse.move(box['x']+60,box['y']+600);pg.mouse.down();pg.mouse.move(box['x']+200,box['y']+600,steps=6);pg.mouse.move(box['x']+300,box['y']+602,steps=6);pg.mouse.up();pg.wait_for_timeout(150)
    chk('parede desenhada',ev("casa().W.length")==nW+1)
    w=json.loads(ev("JSON.stringify(casa().W[casa().W.length-1])"));print('nova parede',w)
    chk('parede reta (0°)',w['a'][1]==w['b'][1])
    # porta na parede nova
    ev("casaApi.tool('door')");pg.mouse.click(box['x']+180,box['y']+600);pg.wait_for_timeout(150)
    chk('porta colocada',ev("casa().O.length")==2)
    # ponto: tomada perto da parede
    ev("casaApi.tool('pt')");pg.wait_for_timeout(100);sp=json.loads(ev("JSON.stringify((function(){var R=casaRooms()[0],q=[R.r.x,R.bb[1]+250],V=document.getElementById('casaV').getBoundingClientRect(),vb=CU.vb;return [V.left+(q[0]-vb[0])/vb[2]*V.width,V.top+(q[1]-vb[1])/vb[3]*V.height]})())"));pg.mouse.click(sp[0],sp[1]);pg.wait_for_timeout(150)
    chk('tomada colocada',ev("casa().P.length")==1)
    # móvel
    ev("casaApi.tool('mov')");pg.mouse.click(box['x']+200,box['y']+300);pg.wait_for_timeout(150)
    chk('móvel colocado',ev("casa().F.length")==1)
    # medir: dois toques
    ev("casaApi.tool('med')");pg.mouse.click(box['x']+100,box['y']+250);pg.mouse.click(box['x']+300,box['y']+250);pg.wait_for_timeout(150)
    chk('medida criada',ev("casa().Q.length")==1)
    # selecionar parede 1 e arrastar a ponta (paredes ligadas acompanham)
    pg.wait_for_timeout(900);ev("casaApi.tool('sel');casaApi.sel('w',1)");a=json.loads(ev("JSON.stringify((function(){var w=casa().W[0],V=document.getElementById('casaV').getBoundingClientRect(),vb=CU.vb;return [V.left+(w.b[0]-vb[0])/vb[2]*V.width,V.top+(w.b[1]-vb[1])/vb[3]*V.height,w.b]})())"))
    linked=ev("cLinked(casa().W[0].b,casa().W[0]).length")
    pg.mouse.move(a[0],a[1]);pg.mouse.down();pg.mouse.move(a[0]+30,a[1],steps=5);pg.mouse.up();pg.wait_for_timeout(150)
    nb=json.loads(ev("JSON.stringify(casa().W[0].b)"));print('ponta',a[2],'->',nb,'ligadas',linked)
    chk('ponta arrastada',nb!=a[2])
    chk('ligadas acompanham',ev("cLinked(casa().W[0].b,casa().W[0]).length")==linked)
    # desfazer
    pg.wait_for_timeout(800);ev("document.querySelector('#casa [data-cu=\"und\"]').click()");pg.wait_for_timeout(200)
    chk('desfazer volta a ponta',json.loads(ev("JSON.stringify(casa().W[0].b)"))==a[2])
    # mudar acabamento face A pra revestida e ver quantitativo
    ev("casaApi.sel('w',1);CU.ptab='A';cuPanel()");ev("document.querySelector('#casaP [data-cff$=\"|rev\"]').click()");pg.wait_for_timeout(100)
    chk('face revestida',ev("cFace(casa().W[0],'L').f")=='rev')
    # quantitativos e PDF
    ev("document.querySelector('#casa [data-ct=\"quant\"]').click()");pg.wait_for_timeout(200)
    chk('tabela de quantitativos',ev("document.querySelectorAll('#casaD table tr').length")>10)
    ev("document.querySelector('#casa [data-ct=\"docs\"]').click()");pg.wait_for_timeout(150);ev("document.querySelector('#casa [data-cu=\"dpdf\"]').click()");pg.wait_for_timeout(500)
    sh=ev("window.__shared");print('shared',sh)
    chk('PDF compartilhado pelo app',len(sh)==1 and sh[0][2]=='application/pdf' and sh[0][1]>20000)
    # salvo no projeto
    pg.wait_for_timeout(800)
    chk('casa salva no projeto',ev("(function(){var a=pLoadAll(),p=a.filter(function(q){return q.id===CUR})[0];return !!(p&&p.current&&p.current.casa&&p.current.casa.W.length)})()"))
    # 3D abre e toca parede
    ev("document.querySelector('#casa [data-ct=\"3d\"]').click()");pg.wait_for_timeout(600)
    chk('3D da casa',ev("c3api.on()")==1 and ev("c3api.objs()")>10)
    # volta pro 3D dos móveis: precisa mostrar móveis normalmente
    ev("document.querySelector('#c3b [data-cx]').click()");pg.wait_for_timeout(200);ev("casaShow(false)");pg.click('#b3d');pg.wait_for_timeout(500)
    chk('3D dos móveis normal',ev("c3api.on()")==0 and not ev("document.getElementById('v3').hidden"))
    pg.screenshot(path=SP+'s_mov3d.png')
    b.close()
print('OK',len(ok),ok);print('FALHOU',bad);print('errs',errs)
