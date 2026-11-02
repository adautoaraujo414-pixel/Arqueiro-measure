from playwright.sync_api import sync_playwright
import json,sys
URL='file:///home/claude/arqueiro-measure-gh/app/src/main/assets/editor.html'
SP='/tmp/claude-0/-home-claude/6d33c1b2-7925-5f03-890b-726a52a5fe54/scratchpad/t107/'
errs=[]
with sync_playwright() as p:
    b=p.chromium.launch(args=['--use-gl=swiftshader','--enable-webgl','--ignore-gpu-blocklist']);pg=b.new_page(viewport={'width':420,'height':860})
    pg.on('pageerror',lambda e:errs.append(str(e)));pg.on('console',lambda m:errs.append('console:'+m.text) if m.type=='error' else None)
    pg.goto(URL);ev=pg.evaluate;ev("window.__noSetup=1");pg.wait_for_timeout(400);ev("try{PR.setupDone=1}catch(e){}")
    pg.click('#bcasa');pg.wait_for_timeout(300);pg.screenshot(path=SP+'s_empty.png')
    ev("document.querySelector('#casa [data-cu=\"demo\"]').click()");pg.wait_for_timeout(300)
    print('rooms',ev("JSON.stringify(casaApi.rooms())"))
    pg.screenshot(path=SP+'s_plan.png')
    # toque numa parede (parede 3, interna)
    ev("casaApi.sel('w',3)");pg.wait_for_timeout(150);pg.screenshot(path=SP+'s_wall.png')
    ev("document.querySelector('#casaP [data-ptab=\"A\"]').click()");pg.wait_for_timeout(100);pg.screenshot(path=SP+'s_wallA.png')
    ev("casaApi.sel('r',4)");pg.wait_for_timeout(100);pg.screenshot(path=SP+'s_room.png')
    # 3D
    ev("document.querySelector('#casa [data-ct=\"3d\"]').click()");pg.wait_for_timeout(700)
    print('gl',ev("(function(){var c=document.getElementById('cv3');return !!c.getContext('webgl')})()"),'objs',ev("c3api.objs()"))
    pg.screenshot(path=SP+'s_3d_fin.png')
    for st in ['alv','reb','acab']:
        ev("c3api.stg('%s')"%st);pg.wait_for_timeout(300);pg.screenshot(path=SP+'s_3d_%s.png'%st)
    ev("c3api.stg('fin')");pg.wait_for_timeout(200)
    # toque no meio da tela
    ev("c3api.tap(210,420)");pg.wait_for_timeout(200);pg.screenshot(path=SP+'s_3d_tap.png')
    ev("c3api.walk(true)");pg.wait_for_timeout(400);pg.screenshot(path=SP+'s_walk.png')
    ev("c3api.walk(false)");ev("document.querySelector('#c3b [data-cx]').click()");pg.wait_for_timeout(300)
    ev("document.querySelector('#casa [data-ct=\"docs\"]').click()");pg.wait_for_timeout(200);ev("document.querySelector('#casa [data-cu=\"dprev\"]').click()");pg.wait_for_timeout(500);pg.screenshot(path=SP+'s_docs.png')
    ev("document.querySelector('#casa [data-ct=\"quant\"]').click()");pg.wait_for_timeout(300);pg.screenshot(path=SP+'s_quant.png')
    b.close()
print('errs',errs)
