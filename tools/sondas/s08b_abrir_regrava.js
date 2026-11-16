var W=function(ms){return new Promise(function(r){setTimeout(r,ms)})};await W(2500);PR.setupDone=1;window.toast=function(){};
var rd=function(){var f=__files['projects.json'];return JSON.parse(decodeURIComponent(escape(atob(f))))[0]};
var a0=rd();var R={antes_updated:a0.updated,antes_egL:a0.current.mods[0].egL};
var a=pLoadAll(),p=a[0];CUR=p.id;loadState(p.current);await W(6000);
var a1=rd();R.depois_updated=a1.updated;R.dataMudouSoDeAbrir=a1.updated!==a0.updated;R.depois_egL=a1.current.mods[0].egL;R.cur=Object.keys(__files).filter(function(k){return /^cur_/.test(k)});
var c=R.cur.length?JSON.parse(decodeURIComponent(escape(atob(__files[R.cur[0]])))):null;R.cur_egL=c?JSON.stringify(c).match(/"egL":\d+/g):null;R.egOn=STD().egOn;
return JSON.stringify(R);
