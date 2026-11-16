/* contadores (antes do editor carregar): ouvintes de evento, texturas e buffers do WebGL */
;(function(){var C=window.__CNT={ouvintes:0,porTipo:{},tex:0,texDel:0,buf:0,bufDel:0,timeouts:0,intervals:0};
var ae=EventTarget.prototype.addEventListener;EventTarget.prototype.addEventListener=function(t){C.ouvintes++;C.porTipo[t]=(C.porTipo[t]||0)+1;return ae.apply(this,arguments)};
var si=window.setInterval;window.setInterval=function(){C.intervals++;return si.apply(this,arguments)};
['WebGLRenderingContext','WebGL2RenderingContext'].forEach(function(n){var P=window[n]&&window[n].prototype;if(!P)return;var ct=P.createTexture,dt=P.deleteTexture,cb=P.createBuffer,db=P.deleteBuffer;P.createTexture=function(){C.tex++;return ct.apply(this,arguments)};P.deleteTexture=function(){C.texDel++;return dt.apply(this,arguments)};P.createBuffer=function(){C.buf++;return cb.apply(this,arguments)};P.deleteBuffer=function(){C.bufDel++;return db.apply(this,arguments)}})})();
