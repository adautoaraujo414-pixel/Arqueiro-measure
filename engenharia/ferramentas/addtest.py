# uso: python3 addtest.py <NomeDoTeste> <arquivo.js> <saida_do_harness.txt> [chave_a_pular,...]
# Acrescenta (ou troca) um teste no fim do EditorWebKitTests.swift com o corpo do JS e um XCTAssertEqual por chave do resultado.
import sys,json,re
name,jsf,outf=sys.argv[1:4];skip=set((sys.argv[4] if len(sys.argv)>4 else '').split(','))
SW='/home/claude/arqueiro-measure/ios/ArquemestreTests/EditorWebKitTests.swift'
js=open(jsf,encoding='utf-8').read().rstrip('\n')
assert '"""#' not in js
txt=open(outf,encoding='utf-8').read();k=txt.find('{');o=json.loads(txt[k:txt.rfind('}')+1])
def sw(v):return json.dumps(v,ensure_ascii=False)
L=['    func '+name+'() async throws {','        let web = try await editor()','        let o = try await run(web, #"""']
L+=['        '+l for l in js.split('\n')]
L+=['        """#)']
for key,v in o.items():
    if key in skip:continue
    if isinstance(v,bool):L.append('        XCTAssertEqual(o["%s"] as? Bool, %s)'%(key,'true' if v else 'false'))
    elif isinstance(v,int):L.append('        XCTAssertEqual(o["%s"] as? Int, %d)'%(key,v))
    elif isinstance(v,str):L.append('        XCTAssertEqual(o["%s"] as? String, %s)'%(key,sw(v)))
    else:raise SystemExit('tipo não previsto em '+key)
L+=['    }']
s=open(SW,encoding='utf-8').read()
i=s.find('    func '+name+'()')
if i>=0:
    j=s.find('\n    func ',i+10)
    if j<0:j=s.rfind('\n}')
    s=s[:i]+'\n'.join(L)+'\n'+s[j+1:] if s[j+1:].startswith('    func ') else s[:i]+'\n'.join(L)+s[j:]
else:
    j=s.rfind('\n}');s=s[:j]+'\n\n'+'\n'.join(L)+s[j:]
open(SW,'w',encoding='utf-8').write(s);print('ok',name,len(o),'chaves')
