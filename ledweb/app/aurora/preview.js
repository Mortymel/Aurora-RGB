// Aproximacion visual de los efectos del firmware; no reproduce brillo fisico.
(()=>{
  const canvas=document.getElementById('demoStrip'),ctx=canvas.getContext('2d');
  const N=80,trail=Array.from({length:N},()=>[0,0,0]);
  let phase=0,previous=performance.now(),previousEffect='';
  const reducedMotion=matchMedia('(prefers-reduced-motion: reduce)');
  let lastStaticFrame='';
  const hsv=(h,s=1,v=1)=>{h=(h%1+1)%1;const f=n=>{const k=(n+h*6)%6;return 255*v*(1-s*Math.max(0,Math.min(k,4-k,1)))};return[f(5),f(3),f(1)]};
  const scale=(c,n)=>c.map(v=>v*n);
  const blend=(a,b,t)=>a.map((v,i)=>v*(1-t)+b[i]*t);
  const unpack=n=>[(n>>16)&255,(n>>8)&255,n&255];
  const palettes=[
    [0x21004b,0xd81b68,0xff732b,0xffd09a],[0x4d164f,0xd84f9f,0xffa6c6,0xffe8d7],
    [0x001c12,0x00683f,0x59b943,0xb5db5c],[0x150005,0x8a0613,0xff3e08,0xffc02a],
    [0x01071e,0x042f6b,0x007eaa,0x5cebd8],[0x8b0010,0xe52b21,0xffe8ba,0x07824b],
    [0xff428d,0xffdce9,0x7ee8ee,0xf9f4ff],[0x180e44,0x9d306e,0xff7d4d,0xffe8b0]];
  const palette=(index,position)=>{const p=((position%1+1)%1)*4,j=Math.floor(p);let t=p-j;t=t*t*(3-2*t);return blend(unpack(palettes[index][j]),unpack(palettes[index][(j+1)%4]),t)};
  function draw(time){
    const s=typeof current==='object'?current:{};
    const staticKey=JSON.stringify([s.state,s.brightness,s.color,s.effect,s.count,canvas.clientWidth,canvas.clientHeight]);
    if(document.hidden || (reducedMotion.matches&&staticKey===lastStaticFrame)){
      previous=time;requestAnimationFrame(draw);return;
    }
    lastStaticFrame=staticKey;
    const dt=Math.min((time-previous)/1000,.1);previous=time;
    phase+=dt*(.08+(s.speed||45)*.025);
    const p=phase%1,wave=(Math.sin(phase*2*Math.PI)+1)/2;
    const color=s.color?[s.color.r,s.color.g,s.color.b]:[255,120,35];
    const effect=s.effect||'Color fijo';
    if(effect!==previousEffect){trail.forEach(c=>c.fill(0));previousEffect=effect;phase=0}
    const rect=canvas.getBoundingClientRect(),dpr=window.devicePixelRatio||1;
    if(!rect.width||!rect.height){requestAnimationFrame(draw);return}
    canvas.width=Math.round(rect.width*dpr);canvas.height=Math.round(rect.height*dpr);ctx.scale(dpr,dpr);
    ctx.fillStyle='#080f18';ctx.fillRect(0,0,rect.width,rect.height);
    const head=Math.floor(p*N),tail=Math.max(4,Math.floor(N/8));
    if(['Confeti','Destellos','Chispas doradas'].includes(effect)){
      trail.forEach(c=>{for(let j=0;j<3;j++)c[j]*=effect==='Chispas doradas'?.92:effect==='Confeti'?.86:.7});
      if(Math.random()<.6)trail[Math.floor(Math.random()*N)]=effect==='Confeti'?hsv(Math.random()):effect==='Chispas doradas'?[255,100+Math.random()*120,5+Math.random()*40]:color.slice();
    }
    for(let i=0;i<N;i++){
      let c=color;const x=i/N;
      switch(effect){
        case 'Arcoiris':c=hsv(p);break;
        case 'Barrido arcoiris':c=hsv(i/N+p);break;
        case 'Respiracion':c=scale(color,.03+wave*.97);break;
        case 'Cometa':{const distance=(head-i+N)%N;c=scale(color,distance<tail?(1-distance/tail)**2:0);break}
        case 'Teatro':c=(i+Math.floor(phase*8))%3===0?color:[0,0,0];break;
        case 'Confeti':case 'Destellos':case 'Chispas doradas':c=trail[i];break;
        case 'Fuego':{const heat=Math.max(0,Math.min(1,.5+.25*Math.sin(x*24-phase*3)+.15*Math.sin(x*51+phase*2)+(Math.random()-.5)*.06));c=[255*heat,170*heat**2,20*heat**3];break}
        case 'Oceano':{const w=(Math.sin(x*4*Math.PI+phase*2)+1)/2;c=hsv(.48+.18*w,230/255,(50+205*w)/255);break}
        case 'Aurora':{const w=(Math.sin(x*3*Math.PI+phase)+1)/2;c=hsv(.30+.48*w,235/255,(20+180*w)/255);break}
        case 'Escaner':c=scale(color,Math.max(0,1-Math.abs(i-wave*(N-1))/Math.max(2,N/20)));break;
        case 'Degradado':c=scale(color,.1+.9*i/(N-1));break;
        case 'Onda de color':c=scale(color,.05+.95*(Math.sin(i*4*Math.PI/N-phase*2*Math.PI)+1)/2);break;
        case 'Estrobo':c=Math.floor(phase*4)%2===0?color:[0,0,0];break;
        case 'Atardecer':case 'Sakura':case 'Bosque':case 'Lava':case 'Mar profundo':{
          const index=['Atardecer','Sakura','Bosque','Lava','Mar profundo'].indexOf(effect);
          c=palette(index,x*.7+phase*.045+.12*Math.sin(x*2*Math.PI-phase*.6));break;
        }
        case 'Plasma':{const v=(Math.sin(x*12+phase*1.8)+Math.sin(x*21-phase*1.1))*.25+.5;c=hsv(v*.8+phase*.04,235/255,(150+105*v)/255);break}
        case 'Galaxia':{c=blend(unpack(0x08052b),unpack(0x4c126a),(Math.sin(x*15+phase*.4)+1)*.5);const hash=(Math.imul(i,2654435761)>>>0);if(hash%19===0)c=blend(c,unpack(0xdceaff),((Math.sin(phase*1.6+(hash%1000)*.01)+1)*.5)**6);break}
        case 'Luciernagas':{const sample=(i+Math.floor(phase*7))%N,hash=Math.imul(sample,2654435761)>>>0,glow=((Math.sin(phase*1.7+(hash%1000)*.01)+1)*.5)**3;c=hash%17===0?blend(unpack(0x000502),unpack(0xc5ff3b),glow):unpack(0x000201);break}
        case 'Lluvia arcoiris':case 'Meteoros':{c=[0,0,0];const streams=effect==='Lluvia arcoiris'?7:3;for(let j=0;j<streams;j++){const head=(phase*(.12+j*.027)+j/streams)%1,distance=(head-x+1)%1,glow=Math.max(0,1-distance/(streams===7?.10:.24))**3;c=blend(c,hsv(j/streams+phase*.03,streams===7?1:130/255),glow)}break}
        case 'Luces navidenas':case 'Caramelos':c=palette(effect==='Caramelos'?6:5,x*3-phase*.08);break;
        case 'Amanecer':c=palette(7,x*.3+phase*.025);break;
        case 'Olas neon':{const v=((Math.sin(x*6*Math.PI-phase*2)+1)*.5)**2;c=hsv(x*.5+phase*.06,1,(15+240*v)/255);break}
        case 'Doble cometa':{const a=Math.max(0,1-((p-x+1)%1)/.22)**3,b=Math.max(0,1-((1-p-x+1)%1)/.22)**3;c=blend(scale(color,a),[color[2],color[0],color[1]],b);break}
        case 'Gradiente vivo':{const t=(Math.sin(x*2*Math.PI-phase*.7)+1)*.5;c=blend(hsv(phase*.025),hsv(phase*.025+.38),t);break}
      }
      c=scale(c,s.state==='ON'?(s.brightness||0)/255:0);
      const css=`rgb(${c.map(v=>Math.round(v)).join(',')})`,width=rect.width/N;
      ctx.fillStyle=css;ctx.shadowColor=css;ctx.shadowBlur=12;
      ctx.fillRect(i*width+width*.08,rect.height*.3,width*.84,rect.height*.4);
    }
    ctx.shadowBlur=0;
    document.getElementById('demoLabel').textContent=`TIRA SIMULADA · ${s.count||320} PIXELES · ${effect} · ${s.state==='ON'?'ENCENDIDA':'APAGADA'}`;
    requestAnimationFrame(draw);
  }
  requestAnimationFrame(draw);
})();
