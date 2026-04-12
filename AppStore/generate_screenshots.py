#!/usr/bin/env python3
"""FocusTimer App Store Screenshot Generator"""
from PIL import Image, ImageDraw, ImageFont
import os

OUT = '/tmp/FocusTimerScreenshots'
os.makedirs(OUT, exist_ok=True)

C_BG = (15,15,19); C_BGS = (26,26,33); C_SFC = (36,36,46)
C_PUR = (124,106,255); C_TEL = (94,234,212); C_WRM = (245,158,11)
C_TXT = (244,244,246); C_TXS = (139,139,158)
C_OK = (52,211,153); C_BAD = (248,113,113)

def F(sz):
    for p in ['/System/Library/Fonts/Helvetica.ttc', '/Library/Fonts/Helvetica.ttc']:
        try: return ImageFont.truetype(p, sz)
        except: pass
    return ImageFont.load_default()

def text(d, s, txt, fill, fnt):
    d.text(s, txt, fill=fill, font=fnt)

def tabbar(d, w, h):
    ty = h-100
    d.rounded_rectangle([30,ty,w-30,ty+70],radius=20,fill=C_BGS)
    pos = [100, 100+(w-200)//4, 100+2*(w-200)//4, 100+3*(w-200)//4, w-100]
    for i,tx in enumerate(pos):
        d.ellipse([tx-12,ty+3,tx+12,ty+27],fill=C_PUR if i==0 else C_SFC)

def draw_today(img, w, h):
    d = ImageDraw.Draw(img)
    f1=F(32);f2=F(20);f3=F(14);f4=F(90)
    text(d,(60,110),'GOOD MORNING',C_TXS,f2)
    text(d,(60,160),'Ready to focus?',C_TXT,f1)
    d.rounded_rectangle([w-200,115,w-55,165],radius=25,fill=C_WRM)
    text(d,(w-175,125),'7 day streak',(30,30,30),f3)
    cx,cy=w//2,h//2-150
    r1=int(h*0.17); r2=r1-45
    ri = Image.new('RGBA',(w,h),(0,0,0,0))
    rd = ImageDraw.Draw(ri)
    rd.ellipse([cx-r1,cy-r1,cx+r1,cy+r1],fill=(124,106,255,100))
    rd.ellipse([cx-r1+25,cy-r1+25,cx+r1-25,cy+r1-25],fill=(0,0,0,0))
    m=Image.new('L',(w,h),0);md=ImageDraw.Draw(m)
    md.pieslice([cx-r1,cy-r1,cx+r1,cy+r1],start=0,end=int(360*0.68),fill=255)
    ri.putalpha(m)
    rgb=Image.new('RGB',(w,h),C_BG)
    ImageDraw.Draw(rgb).ellipse([cx-r1,cy-r1,cx+r1,cy+r1],fill=C_SFC)
    rgb.paste(ri,(0,0),ri)
    ri2=Image.new('RGBA',(w,h),(0,0,0,0));rd2=ImageDraw.Draw(ri2)
    rd2.ellipse([cx-r2,cy-r2,cx+r2,cy+r2],fill=(94,234,212,150))
    rd2.ellipse([cx-r2+18,cy-r2+18,cx+r2-18,cy+r2-18],fill=(0,0,0,0))
    m2=Image.new('L',(w,h),0);md2=ImageDraw.Draw(m2)
    md2.pieslice([cx-r2,cy-r2,cx+r2,cy+r2],start=0,end=int(360*0.45),fill=255)
    ri2.putalpha(m2)
    rgb.paste(ri2,(0,0),ri2)
    img.paste(rgb,(0,0))
    d=ImageDraw.Draw(img)
    text(d,(cx-70,cy-55),'82',C_TXT,f4)
    text(d,(cx-80,cy+55),'min today',C_TXS,f2)
    text(d,(cx-80,cy+90),'Focus: 45m',C_TEL,f3)
    sy=cy+220;sw=(w-180)//3
    for i,(v,l,c) in enumerate([('7','Sessions',C_OK),('45m','Focus',C_PUR),('52m','Longest',C_TEL)]):
        sx=60+i*(sw+20)
        d.rounded_rectangle([sx,sy,sx+sw,sy+120],radius=16,fill=C_BGS)
        text(d,(sx+18,sy+18),v,c,f1)
        text(d,(sx+15,sy+78),l,C_TXS,f3)
    tabbar(d,w,h)

def draw_focus(img, w, h):
    d=ImageDraw.Draw(img)
    f1=F(28);f2=F(18);f3=F(100)
    text(d,(w//2-105,140),'DEEP WORK',C_PUR,f1)
    text(d,(w//2-117,195),'Stay focused',C_TXS,f2)
    cx,cy=w//2,h//2+20;r=int(h*0.22)
    arc=Image.new('RGBA',(w,h),(0,0,0,0));ad=ImageDraw.Draw(arc)
    ad.pieslice([cx-r,cy-r,cx+r,cy+r],start=-90,end=-90+int(360*0.35),fill=C_PUR)
    m=Image.new('L',(w,h),0);md=ImageDraw.Draw(m)
    md.pieslice([cx-r,cy-r,cx+r,cy+r],start=-90,end=-90+int(360*0.35),fill=255)
    arc.putalpha(m)
    rgb=Image.new('RGB',(w,h),C_BG)
    ImageDraw.Draw(rgb).ellipse([cx-r,cy-r,cx+r,cy+r],fill=C_SFC)
    rgb.paste(arc,(0,0),arc)
    img.paste(rgb,(0,0))
    d=ImageDraw.Draw(img)
    text(d,(cx-130,cy-60),'17:33',C_TXT,f3)
    text(d,(cx-75,cy+65),'remaining',C_TXS,f2)
    d.ellipse([w//2-50,h-330,w//2+50,h-230],fill=C_PUR)
    d.ellipse([w//2-180,h-316,w//2-108,h-244],fill=C_BAD)
    tabbar(d,w,h)

def draw_insights(img, w, h):
    d=ImageDraw.Draw(img)
    f1=F(32);f2=F(20);f3=F(14)
    text(d,(60,100),'THIS WEEK',C_TXS,f2)
    text(d,(60,140),'Insights',C_TXT,f1)
    cx2,cy2=60,240;cw,ch=w-120,280
    days=['M','T','W','T','F','S','S'];vals=[0.45,0.72,0.35,0.88,0.60,0.25,0.30]
    bw=(cw-72)//7;gap=12
    for i,(dl,v) in enumerate(zip(days,vals)):
        bx=cx2+i*(bw+gap);bh=int(v*(ch-40));by=cy2+ch-bh
        d.rounded_rectangle([bx,by,bx+bw,cy2+ch],radius=6,fill=C_PUR)
        text(d,(bx+bw//2-5,cy2+ch+5),dl,C_TXS,f3)
    cy3=cy2+ch+50
    d.rounded_rectangle([60,cy3,w-60,cy3+140],radius=20,fill=(94,234,212,25))
    text(d,(90,cy3+18),'BEST DAY',C_TXS,f3)
    text(d,(90,cy3+55),'72 min',C_TEL,f1)
    text(d,(90,cy3+105),'Thursday',C_TXS,f2)
    d.ellipse([w-160,cy3+38,w-110,cy3+88],fill=C_WRM)
    tabbar(d,w,h)

def gen(w,h,fn,fname):
    img=Image.new('RGB',(w,h),C_BG)
    fn(img,w,h)
    p=os.path.join(OUT,fname)
    img.save(p,'PNG')
    print(f"  OK {fname} ({os.path.getsize(p)//1024}KB)")

def main():
    print("FocusTimer Screenshot Generator\n")
    for w,h,n in [(1290,2796,'iPhone67'),(1284,2778,'iPhone65'),(2048,2732,'iPadPro')]:
        print(f"Generating {n} ({w}x{h})...")
        gen(w,h,draw_today,f'{n}_Screen1_Today.png')
        gen(w,h,draw_focus,f'{n}_Screen2_Focus.png')
        gen(w,h,draw_insights,f'{n}_Screen3_Insights.png')
    print(f"\nAll done! Files in: {OUT}")

if __name__=='__main__':
    main()
