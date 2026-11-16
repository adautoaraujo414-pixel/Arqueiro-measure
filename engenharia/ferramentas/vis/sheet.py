# Monta uma folha de comparação: linhas de imagens com título e legenda.
import sys,json
from PIL import Image,ImageDraw,ImageFont
F='/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf';FB='/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf'
def font(sz,b=False):return ImageFont.truetype(FB if b else F,sz)
def wrap(d,t,f,w):
    out=[];line=''
    for word in t.split(' '):
        tt=(line+' '+word).strip()
        if d.textlength(tt,font=f)<=w:line=tt
        else:out.append(line);line=word
    out.append(line);return out
def sheet(title,rows,out,colw=520):
    # rows: [(rótulo da linha, [(img, legenda), ...])]
    pad=24;imgs=[]
    for lab,cells in rows:
        ims=[]
        for path,cap in cells:
            im=Image.open(path).convert('RGB');k=colw/im.width;im=im.resize((colw,int(im.height*k)));ims.append((im,cap))
        imgs.append((lab,ims))
    ncol=max(len(c) for _,c in imgs);W=pad+ncol*(colw+pad)
    tmp=Image.new('RGB',(10,10));d=ImageDraw.Draw(tmp)
    H=pad+50
    for lab,ims in imgs:
        H+=8+32*len(wrap(d,lab,font(23,True),W-2*pad))+max(im.height for im,_ in ims)+12+max(len(wrap(d,c,font(19),colw)) for _,c in ims)*26+pad
    S=Image.new('RGB',(W,H+60),'white');d=ImageDraw.Draw(S);tl=wrap(d,title,font(30,True),W-2*pad)
    for j,l in enumerate(tl):d.text((pad,pad+j*40),l,fill='#111',font=font(30,True))
    y=pad+10+40*len(tl)
    for lab,ims in imgs:
        ls=wrap(d,lab,font(23,True),W-2*pad)
        for j,l in enumerate(ls):d.text((pad,y+j*32),l,fill='#1f4fbf',font=font(23,True))
        y+=8+32*len(ls);h=max(im.height for im,_ in ims)
        for i,(im,cap) in enumerate(ims):
            x=pad+i*(colw+pad);S.paste(im,(x,y));d.rectangle([x-1,y-1,x+im.width,y+im.height],outline='#bbb')
            for j,l in enumerate(wrap(d,cap,font(19),colw)):d.text((x,y+h+12+j*26),l,fill='#222',font=font(19))
        y+=h+12+max(len(wrap(d,c,font(19),colw)) for _,c in ims)*26+pad
    S.save(out);print(out,S.size)
if __name__=='__main__':
    cfg=json.load(open(sys.argv[1]));sheet(cfg['title'],cfg['rows'],cfg['out'],cfg.get('colw',520))
