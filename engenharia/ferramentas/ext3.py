import re,os,sys
src=open('/home/claude/arqueiro-measure/ios/ArquemestreTests/EditorWebKitTests.swift',encoding='utf-8').read()
os.makedirs('ios3',exist_ok=True)
for f in os.listdir('ios3'): os.remove(os.path.join('ios3',f))
parts=re.split(r'\n    func (test\w+)\(\)',src)
n=0
for i in range(1,len(parts),2):
    name=parts[i];body=parts[i+1]
    for k,m in enumerate(re.finditer(r'run\(web, #"""\n(.*?)\n\s*"""#\)',body,re.S)):
        open('ios3/%s_%d.js'%(name,k),'w',encoding='utf-8').write(m.group(1)+'\n');n+=1
print(n)
