import re,json,sys
sw=open('/home/claude/arqueiro-measure/ios/ArquemestreTests/EditorWebKitTests.swift',encoding='utf-8').read()
n=sys.argv[1];body=re.split(r'\n    func '+n+r'\(\)',sw)[1].split('\n    func ')[0]
o=json.loads(''.join(open(sys.argv[2],encoding='utf-8').read().split('\n{',1)[1:]).join(['{','']) if False else '{'+open(sys.argv[2],encoding='utf-8').read().split('\n{',1)[-1] if not open(sys.argv[2]).read().startswith('{') else open(sys.argv[2]).read())
bad=0
for m in re.finditer(r'XCTAssertEqual\(\(?o\["(\w+)"\] as\? (\w+)\)?(?:\?\.(\w+))?(?: \?\? [^,]+)?, ("(?:[^"\\]|\\.)*"|true|false|-?[\d.]+)',body):
    k,ty,conv,exp=m.groups();v=o.get(k)
    e=json.loads(exp) if exp.startswith('"') else exp
    ok=str(v)==e if exp.startswith('"') else (v==(exp=='true') if exp in('true','false') else abs(float(v)-float(exp))<1e-6)
    if not ok:print('FAIL',k,repr(v)[:90],'exp',exp[:90]);bad+=1
print(n,'bad',bad)
