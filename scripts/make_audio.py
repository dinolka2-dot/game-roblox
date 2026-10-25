"""Original synthetic sound effects; deterministic, no downloaded samples."""
import math, random, struct, wave
from pathlib import Path
rng = random.Random(728)
root = Path(__file__).resolve().parents[1] / 'assets/audio'
root.mkdir(parents=True, exist_ok=True)
rate = 22050
specs = {'sword':(0.35,380),'hit':(0.24,95),'fire':(0.7,160),'frost':(0.65,1400),'storm':(0.6,75),'parry':(0.6,1800),'ritual':(1.8,440),'death':(0.9,140)}
for name,(duration,frequency) in specs.items():
    samples=[]; phase=0.0; smooth=0.0
    for i in range(int(rate*duration)):
        t=i/rate; q=t/duration; noise=rng.uniform(-1,1); smooth=smooth*0.8+noise*0.2
        envelope=min(1,t/0.008)*((1-q)**2)
        phase += 2*math.pi*frequency*(1-q*0.65)/rate
        tone=math.sin(phase)
        if name=='sword': value=(noise*0.35+smooth)*math.sin(math.pi*q)**2
        elif name=='hit': value=(tone*0.7+noise*0.3)*envelope
        elif name=='fire': value=(smooth*0.8+tone*0.18)*envelope
        elif name=='frost': value=(math.sin(phase)*0.4+math.sin(phase*1.51)*0.3+noise*0.15)*envelope
        elif name=='storm': value=(noise*0.65+tone*0.3)*envelope*(0.6+0.4*math.cos(t*80))
        elif name=='parry': value=(math.sin(phase)*0.4+math.sin(phase*2.7)*0.25)*envelope
        elif name=='ritual': value=(math.sin(phase)*0.3+math.sin(phase*1.25)*0.2+math.sin(phase*1.5)*0.2)*min(1,t*5)*(1-q)
        else: value=(tone*0.3+smooth*0.6)*envelope
        samples.append(int(max(-1,min(1,value*0.7))*32767))
    with wave.open(str(root/f'{name}.wav'),'wb') as f:
        f.setnchannels(1);f.setsampwidth(2);f.setframerate(rate);f.writeframes(struct.pack('<'+'h'*len(samples),*samples))
print('Created eight original mono PCM sound effects')
