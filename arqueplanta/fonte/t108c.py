from playwright.sync_api import sync_playwright
import json
URL='file:///home/claude/arqueiro-measure-gh/app/src/main/assets/editor.html'
SP='/tmp/claude-0/-home-claude/6d33c1b2-7925-5f03-890b-726a52a5fe54/scratchpad/t107/'
errs=[];ok=[];bad=[]
def chk(n,c,i=''):(ok if c else bad).append(n+('' if c else ' '+str(i)))
with sync_playwright() as p:
    b=p.chromium.launch(args=['--use-gl=swiftshader','--enable-webgl','--ignore-gpu-blocklist']);pg=b.new_page(viewport={'width':1280,'height':800})
    pg.on('pageerror',lambda e:errs.append(str(e)))
    pg.goto(URL);ev=pg.evaluate;ev("window.__noSetup=1");pg.wait_for_timeout(300);ev("PR.setupDone=1")
    chk('botão ArqueCut',ev("document.querySelector('#mcb span').textContent")=='ArqueCut')
    pg.click('#bcasa');pg.wait_for_timeout(200);chk('botões de câmera na planta',ev("document.querySelectorAll('#casaZ [data-cz]').length")==4)
    ev("document.querySelector('#casa [data-cu=\"demo\"]').click()");pg.wait_for_timeout(200)
    w0=ev("CU.vb[2]");pg.click('#casaZ [data-cz="in"]');w1=ev("CU.vb[2]");chk('＋ aproxima',w1<w0,(w0,w1))
    pg.click('#casaZ [data-cz="out"]');pg.click('#casaZ [data-cz="out"]');chk('− afasta',ev("CU.vb[2]")>w1)
    x0=ev("CU.vb[0]");pg.keyboard.press('ArrowRight');chk('seta anda',ev("CU.vb[0]")>x0)
    pg.click('#casaZ [data-cz="fit"]');pg.screenshot(path=SP+'zoom_plan.png')
    pg.click('#casaZ [data-cz="3d"]');pg.wait_for_timeout(500);chk('🧊 levanta em 3D',ev("c3api.on()")==1)
    chk('botões de câmera no 3D',ev("document.querySelectorAll('#cz3 [data-cz]').length")==8)
    pg.click('#cz3 [data-cz="up"]');pg.click('#cz3 [data-cz="in"]');pg.click('#cz3 [data-cz="rr"]');pg.wait_for_timeout(200);pg.screenshot(path=SP+'zoom_3d.png')
    pg.click('#cz3 [data-cz="mv"]');chk('✥ arrastar liga',ev("document.querySelector('#cz3 [data-cz=\"mv\"]').style.background!==''"))
    box=pg.locator('#cv3').bounding_box();pg.mouse.move(box['x']+500,box['y']+300);pg.mouse.down();pg.mouse.move(box['x']+600,box['y']+330,steps=4);pg.mouse.up();pg.wait_for_timeout(200)
    pg.click('#cz3 [data-cz="home"]');ev("document.querySelector('#c3b [data-cx]').click()");pg.wait_for_timeout(200)
    chk('câmera some fora da casa',ev("document.getElementById('cz3').hidden"))
    b.close()
print('OK',ok);print('FALHOU',bad);print('errs',errs)
