from playwright.sync_api import sync_playwright
import json
URL='file:///home/claude/arqueiro-measure-gh/app/src/main/assets/editor.html'
SP='/tmp/claude-0/-home-claude/6d33c1b2-7925-5f03-890b-726a52a5fe54/scratchpad/t107/'
ok=[];bad=[];errs=[]
def chk(n,c,i=''):(ok if c else bad).append(n+('' if c else ' '+str(i)))
with sync_playwright() as p:
    b=p.chromium.launch(args=['--use-gl=swiftshader','--enable-webgl','--ignore-gpu-blocklist']);pg=b.new_page(viewport={'width':420,'height':860});ev=pg.evaluate;pg.on('pageerror',lambda e:errs.append(str(e)))
    pg.goto(URL);ev("window.__noSetup=1");pg.wait_for_timeout(300);ev("PR.setupDone=1")
    pg.click('#bcasa');pg.wait_for_timeout(200);ev("document.querySelector('#casa [data-cu=\"demo\"]').click()");pg.wait_for_timeout(200)
    ev("document.querySelector('#casaTools [data-ct=\"3d\"]').click()");pg.wait_for_timeout(500)
    ev("c3api.info({k:'w',id:3,s:3000,sd:'L'});window.re3&&0");ev("void 0");pg.evaluate("document.getElementById('cv3').dispatchEvent(new Event('noop'))")
    ev("c3api.stg('fin')");pg.wait_for_timeout(300)
    hs=ev("Array.prototype.map.call(document.querySelectorAll('#ah3 [data-ah]'),function(d){return d.dataset.ah}).join()")
    chk('3 setinhas na parede (pontas e altura)',hs=='ha,hb,hh',hs)
    h0=ev("cH(cBy(casa().W,3))")
    el=pg.locator('#ah3 [data-ah="hh"]');bx=el.bounding_box()
    pg.mouse.move(bx['x']+16,bx['y']+16);pg.mouse.down();pg.mouse.move(bx['x']+16,bx['y']-30,steps=6);pg.mouse.up();pg.wait_for_timeout(200)
    h1=ev("cH(cBy(casa().W,3))");chk('seta de cima sobe a parede',h1>h0,(h0,h1))
    b0=json.loads(ev("JSON.stringify(cBy(casa().W,3).b)"))
    el=pg.locator('#ah3 [data-ah="hb"]');bx=el.bounding_box()
    pg.mouse.move(bx['x']+16,bx['y']+16);pg.mouse.down();pg.mouse.move(bx['x']+60,bx['y']+30,steps=6);pg.mouse.up();pg.wait_for_timeout(200)
    b1=json.loads(ev("JSON.stringify(cBy(casa().W,3).b)"));chk('seta da ponta aumenta/diminui',b1!=b0,(b0,b1))
    nW=ev("casa().W.length")
    ev("document.querySelector('#c3b [data-cnw]').click()");box=pg.locator('#cv3').bounding_box()
    pg.mouse.move(box['x']+150,box['y']+500);pg.mouse.down();pg.mouse.move(box['x']+250,box['y']+520,steps=6);pg.mouse.up();pg.wait_for_timeout(300)
    chk('✏ Nova parede no 3D',ev("casa().W.length")==nW+1,ev("casa().W.length"))
    pg.screenshot(path=SP+'ah_house.png')
    chk('desfazer existe no histórico',ev("HIST.length")>0)
    b.close()
print('OK',ok);print('FALHOU',bad);print('errs',errs)
