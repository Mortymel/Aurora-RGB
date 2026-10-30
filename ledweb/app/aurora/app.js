'use strict';
let current={state:'ON',brightness:100,speed:45,color:{r:185,g:135,b:211},effect:'Atardecer',count:320,effects:[]};
(()=>{
const $=id=>document.getElementById(id);
const isDemo=document.documentElement.dataset.demo==='true';
const transport=AuroraTransport.createTransport({demo:isDemo});
let connected=false,commandRevision=0,commandsInFlight=0;
function connectionStatus(ok,message){
 connected=ok;document.body.classList.toggle('disconnected',!ok);
 $('connection').textContent=message||(ok?(isDemo?'Wi-Fi conectado · demo':'Controlador conectado'):'Sin conexión · reintentando…');
 document.querySelector('.status-pill').textContent=ok?(isDemo?'Demo conectada':'Conectado'):'Sin conexión';
}
if(!isDemo){
 document.body.classList.add('live','full');
 document.querySelectorAll('.preview-tools,.demo-chip,.demo-callout,.simulation-note').forEach(el=>el.hidden=true);
 $('addControllerSubmit').textContent='Abrir controlador';
 $('connection').textContent='Conectando con la ESP32…';
 const about=$('dialog-about').querySelectorAll('p');
 about[0].textContent='Aurora controla tu tira desde la ESP32: color, efectos, brillo, horarios y Home Assistant.';
 about[1].textContent='La esfera representa el color elegido. La tira animada aproxima el efecto; el brillo físico puede variar.';
 about[2].textContent='Tus ambientes se guardan en este navegador. Los horarios se guardan en la ESP32; la cuenta atrás se pierde al reiniciar la placa.';
}

const icons=name=>`<svg aria-hidden="true"><use href="#icon-${name}"/></svg>`;
const gradients={sunset:'linear-gradient(145deg,#352652,#b44e77,#edb18a)',ocean:'linear-gradient(145deg,#101d49,#176c92,#75c6c1)',sakura:'linear-gradient(145deg,#663266,#cc7dac,#ebc0c3)',forest:'linear-gradient(145deg,#14392d,#4e8760,#a2bd78)',galaxy:'radial-gradient(ellipse at 70% 20%,#a48cda,transparent 50%),linear-gradient(145deg,#192045,#564074,#9e719c)',fire:'linear-gradient(145deg,#46192d,#b54530,#eab65a)',neon:'linear-gradient(145deg,#453485,#bf65bd,#64babe)',candy:'linear-gradient(145deg,#dd82ac,#b6c3e5,#a1d3d3)'};
const ambient=new Set([0,3,8,9,10,12,13,15,16,17,18,19,20,21,28,31]),movement=new Set([4,11,23,24,29,30]);
const details=[
['Color a tu manera.','Un color elegido por ti.','sakura'],['Un mundo de color.','Todos los colores, en toda la tira.','neon'],['Deja fluir el color.','Un arcoíris que recorre tu espacio.','neon'],['Respira despacio.','La intensidad sube y baja suavemente.','sakura'],['Una estela de luz.','Un punto que deja su rastro.','sunset'],['En primera fila.','Luz alternada con ritmo.','neon'],['Un poco de alegría.','Pequeñas chispas de muchos colores.','candy'],['Momentos que brillan.','Destellos del color que elijas.','sakura'],['El calor de una llama.','Ámbar y naranja en movimiento.','fire'],['Déjate llevar.','Ondas entre azul y turquesa.','ocean'],['La noche se mueve.','Verdes y violetas envolventes.','galaxy'],['De un lado al otro.','Un haz que va y vuelve.','ocean'],['Un color, mil matices.','De suave a intenso a lo largo de la tira.','sakura'],['El color tiene ritmo.','Ondas del color que elijas.','neon'],['Luz a pulsos.','Destellos rápidos; empieza con brillo bajo.','galaxy'],['La última luz del día.','Violeta, rosa y ámbar sin prisas.','sunset'],['Una pausa en rosa.','Tonos suaves, cálidos y envolventes.','sakura'],['Un respiro verde.','Una paleta inspirada en el bosque.','forest'],['Luz desde dentro.','Rojo profundo y naranja cálido.','fire'],['Todo queda en calma.','Azul profundo, agua y turquesa.','ocean'],['Energía que fluye.','Ondas de colores que se entrelazan.','neon'],['Tu pequeña galaxia.','Una nebulosa con estrellas suaves.','galaxy'],['Luces en el jardín.','Pequeños puntos cálidos entre verdes.','forest'],['Que llueva color.','Estelas de arcoíris en movimiento.','neon'],['Pide un deseo.','Tres estelas que cruzan tu espacio.','galaxy'],['Un brillo dorado.','Chispas cálidas con una estela suave.','fire'],['Una noche especial.','Rojo, verde y blanco cálido.','forest'],['Un momento dulce.','Rosa, blanco y azul pastel.','candy'],['La luz vuelve.','Un amanecer de violetas y ámbar.','sunset'],['Déjate sorprender.','Ondas de color con un pulso intenso.','neon'],['Dos caminos de luz.','Estelas que viajan en sentidos opuestos.','ocean'],['Siempre distinto.','Dos tonos se mezclan con suavidad.','neon']
];
let cfg=null,activeView='home',category='Todos',editingSchedule=0,toastTimer,pendingTimer,pendingPatch={},requestChain=Promise.resolve(),pollBusy=false;
function readSaved(key,fallback){try{const value=JSON.parse(localStorage.getItem(isDemo?key:'aurora.live.'+key));return value??fallback}catch{return fallback}}
const prefs={name:readSaved('aurora.name','Escritorio'),appearance:readSaved('aurora.appearance','light')};
let controllers=readSaved('aurora.controllers',[{id:'default',name:prefs.name,host:'192.168.1.50'}]);
if(!Array.isArray(controllers))controllers=[];
controllers=controllers.filter(device=>device&&typeof device.name==='string'&&typeof device.host==='string'&&/^[a-z0-9_-]{1,80}$/.test(device.id));
if(!controllers.length)controllers=[{id:'default',name:'Escritorio',host:'192.168.1.50'}];
let selectedController=readSaved('aurora.selectedController','default');
if(!controllers.some(device=>device.id===selectedController))selectedController=controllers[0].id;
prefs.name=controllers.find(device=>device.id===selectedController).name;
if(!isDemo){
 const local=controllers.find(device=>device.host===location.host);
 controllers=controllers.filter(device=>device.id!=='default'||device.host===location.host);
 if(!local)controllers.unshift({id:'local',name:'Mi luz',host:location.host});
 selectedController=(local||controllers[0]).id;prefs.name=(local||controllers[0]).name;
}
let selectionGeneration=0;
let favorites=readSaved('aurora.favorites',['Atardecer','Galaxia','Sakura','Mar profundo']);
let savedScenes=readSaved('aurora.scenes',[]);
if(!Array.isArray(favorites))favorites=[];if(!Array.isArray(savedScenes))savedScenes=[];
function persist(key,value){try{localStorage.setItem((isDemo?'aurora.':'aurora.live.aurora.')+key,JSON.stringify(value))}catch{}}
function toast(message){$('toast').textContent=message;$('toast').hidden=false;clearTimeout(toastTimer);toastTimer=setTimeout(()=>$('toast').hidden=true,3600)}
function run(fn){return async(...args)=>{try{return await fn(...args)}catch(error){toast(error.message||'No se pudo completar la acción')}}}
async function api(path,data,deviceId=selectedController){return transport(path,data,deviceId)}

function meta(name){const index=current.effects.indexOf(name),d=details[index]||details[0];return {index,title:d[0],description:d[1],gradient:gradients[d[2]],group:ambient.has(index)?'Ambiente':movement.has(index)?'Movimiento':'Fiesta'}}
function hex(color=current.color){return '#'+[color.r,color.g,color.b].map(v=>Number(v).toString(16).padStart(2,'0')).join('')}
function rgb(value){return {r:parseInt(value.slice(1,3),16),g:parseInt(value.slice(3,5),16),b:parseInt(value.slice(5,7),16)}}
function theme(){let value=prefs.appearance;if(value==='auto')value=matchMedia('(prefers-color-scheme:dark)').matches?'dark':'light';document.documentElement.dataset.theme=value;$('appearance').value=prefs.appearance}
theme();matchMedia('(prefers-color-scheme:dark)').addEventListener('change',theme);
let lastOrbColor='';
function paintOrb(color){
 const key=[color.r,color.g,color.b].join(',');if(key===lastOrbColor)return;lastOrbColor=key;
 const canvas=$('orbCanvas'),size=360,ctx=canvas.getContext('2d');canvas.width=size;canvas.height=size;
 const frame=ctx.createImageData(size,size),data=frame.data;
 for(let y=0;y<size;y++)for(let x=0;x<size;x++){
  const nx=(x+.5-size/2)/(size/2),ny=(y+.5-size/2)/(size/2),r2=nx*nx+ny*ny;
  if(r2>1)continue;
  const nz=Math.sqrt(1-r2),diffuse=Math.max(0,nx*-.42+ny*-.5+nz*.76);
  const highlight=Math.exp(-((nx+.34)**2+(ny+.40)**2)/.075);
  const rim=Math.pow(nz,.16);
  const texture=1-.014*(.5+.5*Math.cos(x*2.4));
  const intensity=Math.min(1,(.44+.52*diffuse+.10*highlight)*(.78+.22*rim))*texture;
  const i=(y*size+x)*4;
  data[i]=Math.round(color.r*intensity);data[i+1]=Math.round(color.g*intensity);data[i+2]=Math.round(color.b*intensity);data[i+3]=255;
 }
 ctx.putImageData(frame,0,0);
}
function percent(){return Math.round(current.brightness/255*100)}
function renderState(){
 const on=current.state==='ON';$('power').setAttribute('aria-pressed',String(on));$('power').setAttribute('aria-label',on?'Apagar luz':'Encender luz');
 $('previewEffect').textContent=on?current.effect:'Luz apagada';$('previewBrightness').textContent=on?percent()+'%':'Apagada';$('previewPixels').textContent=current.count+' px';
 $('colorHexValue').textContent=hex().toUpperCase();
 $('orb').style.backgroundColor='rgb('+[current.color.r,current.color.g,current.color.b].join(',')+')';
 $('orb').style.setProperty('--orb-color',hex());
 paintOrb(current.color);
 $('orb').setAttribute('aria-label','Color '+hex().toUpperCase());
 $('orb').style.color=(current.color.r*.299+current.color.g*.587+current.color.b*.114)>155?'#202233':'#ffffff';
 $('brightnessValue').textContent=percent()+'%';$('speedValue').textContent=current.speed;
 if(document.activeElement!==$('brightness'))$('brightness').value=current.brightness;
 if(document.activeElement!==$('speed'))$('speed').value=current.speed;
 $('orb').style.opacity='1';
 document.querySelectorAll('[data-device-name]').forEach(el=>el.textContent=prefs.name);
 if(connected)connectionStatus(true,!isDemo&&!current.wifi?'Conectado por punto de acceso':undefined);
 const remaining=current.timer_remaining||0;
 const timerText=remaining?'Acción pendiente en '+Math.ceil(remaining/60)+' min':'Apagar después de un tiempo';
 $('timerSummary').textContent=timerText;$('scheduleTimerSummary').textContent=remaining?timerText:'Una acción dentro de unos minutos';
 $('timerActive').hidden=!remaining;$('timerActive').textContent=remaining?'Cuenta atrás activa: '+Math.ceil(remaining/60)+' minutos restantes.':'';
 $('cancelTimer').disabled=!remaining;
 $('deviceClock').textContent=current.clock_valid?(current.clock||'').slice(11):'Sin sincronizar';
 $('mqttSummary').textContent=(current.mqtt?'Conectado':'Desconectado')+(isDemo?' · simulado':'');$('mqttDialogStatus').textContent='MQTT '+$('mqttSummary').textContent;
 document.querySelectorAll('.effect-item').forEach(row=>row.classList.toggle('active',row.dataset.effect===current.effect));
 document.querySelectorAll('.effect-check').forEach(icon=>icon.hidden=icon.closest('.effect-item').dataset.effect!==current.effect);
 document.querySelectorAll('.swatches button').forEach(button=>button.classList.toggle('selected',button.dataset.color===hex()));
}
async function refresh(){
 if(pollBusy||commandsInFlight||Object.keys(pendingPatch).length)return;
 pollBusy=true;const deviceId=selectedController,generation=selectionGeneration,revision=commandRevision;
 try{const next=await api('state',undefined,deviceId);
  if(deviceId!==selectedController||generation!==selectionGeneration||revision!==commandRevision)return;
  const first=current.effects.length!==next.effects.length;current={...current,...next};connectionStatus(true);renderState();
  if(first){renderEffects();renderHomeScenes()}
 }catch(error){if(generation===selectionGeneration)connectionStatus(false);throw error}finally{pollBusy=false}
}
async function sendLight(patch){
 if(!connected)throw Error('Espera a que el controlador vuelva a conectarse.');
 const deviceId=selectedController,generation=selectionGeneration;commandRevision++;commandsInFlight++;
 current={...current,...patch};renderState();
 const operation=async()=>{
  try{const result=await api('light',patch,deviceId);
   if(deviceId===selectedController&&generation===selectionGeneration){current={...current,...result,...pendingPatch};connectionStatus(true);renderState()}
  }catch(error){if(generation===selectionGeneration)connectionStatus(false);throw error}
  finally{commandsInFlight--}
 };
 requestChain=requestChain.catch(()=>{}).then(operation);return requestChain;
}
function stageLight(patch){if(!connected){toast('Sin conexión con el controlador');return}pendingPatch={...pendingPatch,...patch};current={...current,...patch};renderState();clearTimeout(pendingTimer);pendingTimer=setTimeout(flushLight,140)}
function flushLight(){clearTimeout(pendingTimer);if(!Object.keys(pendingPatch).length)return;const patch=pendingPatch;pendingPatch={};run(()=>sendLight(patch))()}
let configChain=Promise.resolve();
async function saveConfig(patch){
 const id=selectedController,generation=selectionGeneration;
 const operation=async()=>{
  const latest=await api('config',undefined,id),body={...latest,wifi_password:'',mqtt_password:'',...patch};
  const result=await api('config',body,id);
  if(id!==selectedController||generation!==selectionGeneration)return;
  cfg={...latest,...patch};delete cfg.wifi_password;delete cfg.mqtt_password;renderConfig();
  if(result.reconnecting&&!isDemo){connectionStatus(false,'Red guardada · reconectando…');return}
  await refresh();
 };
 configChain=configChain.catch(()=>{}).then(operation);return configChain;
}
function navigate(view){activeView=view;$('stripPreview').hidden=view==='schedules'||view==='settings';document.querySelectorAll('.view').forEach(el=>el.hidden=el.id!=='view-'+view);document.querySelectorAll('[data-view]').forEach(button=>{if(button.dataset.view===view)button.setAttribute('aria-current','page');else button.removeAttribute('aria-current')});$('appScroll').scrollTop=0;if(view==='schedules')renderSchedules();if(view==='effects')renderEffects()}
document.querySelectorAll('[data-view]').forEach(button=>button.onclick=()=>navigate(button.dataset.view));
document.querySelectorAll('[data-viewport]').forEach(button=>button.onclick=()=>{document.body.classList.toggle('full',button.dataset.viewport==='full');document.querySelectorAll('[data-viewport]').forEach(b=>b.setAttribute('aria-pressed',String(b===button)))});
$('power').onclick=run(()=>sendLight({state:current.state==='ON'?'OFF':'ON'}));
for(const [id,key] of [['brightness','brightness'],['speed','speed']]){$(id).oninput=()=>stageLight({[key]:Number($(id).value)});$(id).onchange=flushLight}
for(const [label,color] of [['Violeta','#b987d3'],['Cálido','#e5aa83'],['Azul','#7aafd4'],['Verde','#8fc3ac'],['Rosa','#e5c9db']]){const b=document.createElement('button');b.style.setProperty('--color',color);b.dataset.color=color;b.setAttribute('aria-label','Color '+label);b.onclick=run(()=>sendLight({state:'ON',effect:'Color fijo',color:rgb(color)}));$('swatches').append(b)}
async function chooseEffect(name){await sendLight({state:'ON',effect:name})}
function renderEffects(){
 const container=$('effectList');container.replaceChildren();
 const query=$('effectSearch').value.toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g,'');
 const visible=current.effects.filter(name=>{const d=meta(name);return (category==='Todos'||category===d.group||(category==='Favoritos'&&favorites.includes(name)))&&name.toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g,'').includes(query)});
 for(const name of visible){const d=meta(name),row=document.createElement('div');row.className='effect-item'+(name===current.effect?' active':'');row.dataset.effect=name;
  const pick=document.createElement('button');pick.className='effect-pick';pick.setAttribute('aria-label','Aplicar '+name);pick.innerHTML='<span class="effect-thumb"></span><span class="effect-info"><strong></strong><small></small></span>'+icons('check');
  pick.querySelector('.effect-thumb').style.background=d.gradient;pick.querySelector('strong').textContent=name;pick.querySelector('small').textContent=d.group+' · '+d.description;const check=pick.querySelector('svg');check.classList.add('effect-check');check.hidden=name!==current.effect;pick.onclick=run(()=>chooseEffect(name));
  const star=document.createElement('button');star.className='favorite-button';star.setAttribute('aria-label',(favorites.includes(name)?'Quitar':'Añadir')+' '+name+' de favoritos');star.setAttribute('aria-pressed',String(favorites.includes(name)));star.innerHTML=icons('star');star.onclick=()=>{favorites=favorites.includes(name)?favorites.filter(n=>n!==name):[...favorites,name];persist('favorites',favorites);renderEffects();renderHomeScenes()};row.append(pick,star);container.append(row);
 }
 $('effectsEmpty').hidden=visible.length>0;$('savedScenes').hidden=category!=='Favoritos'||!savedScenes.length;
 $('customSceneList').replaceChildren();for(const scene of savedScenes){const row=document.createElement('div');row.className='saved-scene-row';const apply=document.createElement('button');apply.innerHTML='<strong></strong><small></small>';apply.querySelector('strong').textContent=scene.name;apply.querySelector('small').textContent=scene.effect+' · '+Math.round(scene.brightness/255*100)+'%';apply.onclick=run(()=>sendLight({state:'ON',effect:scene.effect,color:scene.color,brightness:scene.brightness,speed:scene.speed}));const remove=document.createElement('button');remove.className='icon-button';remove.innerHTML=icons('trash');remove.setAttribute('aria-label','Eliminar ambiente '+scene.name);remove.onclick=()=>{savedScenes=savedScenes.filter(s=>s.id!==scene.id);persist('scenes',savedScenes);renderEffects()};row.append(apply,remove);$('customSceneList').append(row)}
}
$('effectSearch').oninput=renderEffects;
function setCategory(value){category=value;document.querySelectorAll('[data-category]').forEach(button=>button.setAttribute('aria-pressed',String(button.dataset.category===value)));renderEffects()}
document.querySelectorAll('[data-category]').forEach(button=>button.onclick=()=>setCategory(button.dataset.category));
function renderHomeScenes(){const container=$('homeScenes');container.replaceChildren();const names=favorites.filter(n=>current.effects.includes(n)).slice(0,4);for(const name of names){const b=document.createElement('button');b.className='scene-card';b.style.background=meta(name).gradient;b.innerHTML='<small></small><strong></strong>';b.querySelector('small').textContent=meta(name).group.toUpperCase();b.querySelector('strong').textContent=name;b.onclick=run(()=>chooseEffect(name));container.append(b)}if(!names.length){const p=document.createElement('p');p.className='helper';p.textContent='Marca una estrella en Efectos para guardar tus favoritos.';container.append(p)}}
$('showFavorites').onclick=()=>{navigate('effects');setCategory('Favoritos')};
function renderConfig(){if(!cfg)return;$('deviceDescription').textContent=(cfg.chip||'ESP32')+' · '+cfg.count+' píxeles';$('stripSummary').textContent=cfg.count+' píxeles · GPIO'+cfg.gpio+' · '+(cfg.grb?'GRB':'RGB');$('wifiSummary').textContent=cfg.ssid||'Sin red configurada';if(![...$('timezone').options].some(o=>o.value===String(cfg.utc_offset))){const o=new Option('UTC '+(cfg.utc_offset/60),String(cfg.utc_offset));$('timezone').add(o)}$('timezone').value=String(cfg.utc_offset);$('timezoneLabel').textContent=cfg.utc_offset===-240?'Bolivia · UTC−04:00':'UTC '+(cfg.utc_offset>=0?'+':'−')+String(Math.floor(Math.abs(cfg.utc_offset)/60)).padStart(2,'0')+':'+String(Math.abs(cfg.utc_offset)%60).padStart(2,'0');renderSchedules()}
const dayNames=['Lu','Ma','Mi','Ju','Vi','Sá','Do'];
function renderControllers(){
 for(const id of ['controllerList','controllerPicker']){
  $(id).replaceChildren();
  for(const device of controllers){
   const button=document.createElement('button');button.className='controller-item';button.dataset.controller=device.id;
   button.setAttribute('aria-pressed',String(device.id===selectedController));
   button.innerHTML='<span class="small-icon">'+icons('chip')+'</span><span class="controller-info"><strong></strong><small></small></span>'+icons(device.id===selectedController?'check':'chevron');
   button.querySelector('strong').textContent=device.name;
   button.querySelector('small').textContent=device.host+' · '+(device.id===selectedController?'Seleccionado':(isDemo?'Simulado':'Abrir'));
   button.onclick=run(async()=>{await selectController(device.id);if($('dialog-controllers').open)$('dialog-controllers').close()});$(id).append(button);
  }
 }
}
async function selectController(id){
 const target=controllers.find(item=>item.id===id);
 if(!isDemo&&target&&target.host!==location.host){location.assign(AuroraTransport.controllerAddress(target.host));return}

 const generation=++selectionGeneration;flushLight();await Promise.all([requestChain.catch(()=>{}),configChain.catch(()=>{})]);
 if(generation!==selectionGeneration)return;
 const device=controllers.find(item=>item.id===id);if(!device)throw Error('Controlador no encontrado');
 selectedController=id;prefs.name=device.name;persist('selectedController',id);
 const [config,state]=await Promise.all([api('config',undefined,id),api('state',undefined,id)]);
 if(generation!==selectionGeneration)return;
 cfg=config;current=state;connectionStatus(true);renderState();renderConfig();renderEffects();renderHomeScenes();renderControllers();
}
function parseControllerHost(value){
 const text=value.trim();let url;try{url=new URL(text.includes('://')?text:'http://'+text)}catch{throw Error('Introduce una IP o un nombre de red válido')}
 if(!['http:','https:'].includes(url.protocol)||url.username||url.password||url.search||url.hash||url.pathname!=='/'||!url.hostname.includes('.')||url.hostname.includes(' '))throw Error('Introduce solo la IP o el nombre .local de la ESP32');
 if(/^[\d.]+$/.test(url.hostname)&&(!/^\d{1,3}(\.\d{1,3}){3}$/.test(url.hostname)||url.hostname.split('.').some(n=>Number(n)>255)))throw Error('La IP debe tener cuatro números entre 0 y 255');
 return url.host.toLowerCase();
}
function daysText(mask){if(mask===127)return'Todos los días';if(mask===31)return'Lunes a viernes';if(mask===96)return'Fin de semana';return dayNames.filter((_,i)=>mask&(1<<i)).join(' · ')}
function renderSchedules(){if(!cfg)return;const list=$('scheduleList');list.replaceChildren();cfg.schedules.forEach((s,index)=>{const row=document.createElement('div');row.className='schedule-item'+(s.enabled?'':' inactive');const edit=document.createElement('button');edit.className='schedule-main';edit.setAttribute('aria-label','Editar horario '+(index+1));edit.innerHTML='<strong></strong><p></p><small></small>';edit.querySelector('strong').textContent=s.time;edit.querySelector('p').textContent=(s.on?'Encender':'Apagar')+' '+prefs.name;edit.querySelector('small').textContent=s.enabled?daysText(s.days):'Horario '+(index+1)+' · desactivado';edit.onclick=()=>openSchedule(index);const toggle=document.createElement('button');toggle.className='toggle';toggle.setAttribute('aria-pressed',String(s.enabled));toggle.setAttribute('aria-label',(s.enabled?'Desactivar':'Activar')+' horario '+(index+1));toggle.onclick=run(async()=>{const schedules=cfg.schedules.map((row,i)=>({...row,enabled:i===index?!row.enabled:row.enabled}));await saveConfig({schedules});toast(s.enabled?'Horario desactivado':'Horario activado')});row.append(edit,toggle);list.append(row)});$('addSchedule').disabled=cfg.schedules.every(s=>s.enabled);$('addSchedule').setAttribute('aria-label',$('addSchedule').disabled?'Ya hay cuatro horarios activos':'Añadir horario')}
for(const [i,name] of dayNames.entries()){const label=document.createElement('label'),input=document.createElement('input');input.type='checkbox';input.value=i;input.checked=true;input.setAttribute('aria-label',['Lunes','Martes','Miércoles','Jueves','Viernes','Sábado','Domingo'][i]);label.append(input,document.createTextNode(name));$('scheduleDays').append(label)}
function openSchedule(index){editingSchedule=index;const s=cfg.schedules[index];$('scheduleHeading').textContent=s.enabled?'Editar horario.':'Nuevo horario.';$('scheduleTime').value=s.time;$('scheduleAction').value=s.on?'on':'off';$('scheduleEnabled').checked=s.enabled;document.querySelectorAll('#scheduleDays input').forEach((input,i)=>input.checked=Boolean(s.days&(1<<i)));$('deleteSchedule').hidden=!s.enabled;$('dialog-schedule').showModal()}
$('addSchedule').onclick=()=>{const index=cfg.schedules.findIndex(s=>!s.enabled);if(index>=0){openSchedule(index);$('scheduleEnabled').checked=true}};
$('syncClock').onclick=run(async()=>{await api('clock',{epoch:Math.floor(Date.now()/1000)});await refresh();toast('Reloj sincronizado con este dispositivo')});
$('timezone').onchange=run(async()=>{await saveConfig({utc_offset:Number($('timezone').value)});toast('Zona horaria guardada')});
async function openSheet(name){
 if(!cfg)cfg=await api('config');
 if(name==='color'){$('customColor').value=hex();$('hexColor').value=hex().toUpperCase()}
 if(name==='device'){$('deviceName').value=prefs.name;$('pixelCount').value=cfg.count;$('pixelCount').max=cfg.max_count||1600;$('gpio').replaceChildren();for(const pin of cfg.available_pins){const o=document.createElement('option');o.value=pin;o.textContent='GPIO '+pin;$('gpio').append(o)}$('gpio').value=cfg.gpio;$('colorOrder').value=cfg.grb?'grb':'rgb'}
 if(name==='wifi'){$('wifiSsid').value=cfg.ssid;$('wifiPassword').value='';$('clearWifiPassword').checked=false}
 if(name==='mqtt'){$('mqttHost').value=cfg.mqtt_host;$('mqttPort').value=cfg.mqtt_port;$('mqttUser').value=cfg.mqtt_user;$('mqttPassword').value='';$('clearMqttPassword').checked=false}
 if(name==='scene')$('sceneName').value=current.effect;
 if(name==='controllers')renderControllers();
 if(name==='add-controller'){$('newControllerName').value='';$('newControllerHost').value=''}
 $('dialog-'+name).showModal();
}
document.querySelectorAll('[data-dialog]').forEach(button=>button.onclick=run(()=>openSheet(button.dataset.dialog)));
document.querySelectorAll('[data-close]').forEach(button=>button.onclick=()=>button.closest('dialog').close());
document.querySelectorAll('dialog').forEach(dialog=>dialog.addEventListener('click',event=>{const rect=dialog.getBoundingClientRect();if(event.target===dialog&&(event.clientX<rect.left||event.clientX>rect.right||event.clientY<rect.top||event.clientY>rect.bottom))dialog.close()}));
function onSubmit(id,handler){let busy=false;$(id).addEventListener('submit',event=>{
 event.preventDefault();if(busy)return;busy=true;
 const button=event.submitter;if(button)button.disabled=true;
 run(handler)().finally(()=>{busy=false;if(button)button.disabled=false});
})}
$('openAddController').onclick=run(async()=>{$('dialog-controllers').close();await openSheet('add-controller')});
onSubmit('addControllerForm',async()=>{
 const name=$('newControllerName').value.trim(),host=parseControllerHost($('newControllerHost').value);
 if(!name)throw Error('Escribe un nombre para esta luz');
 if(!isDemo){
 const origin=AuroraTransport.controllerAddress($('newControllerHost').value);
 if(!controllers.some(d=>d.host===host)){controllers.push({id:'device_'+Date.now(),name,host});persist('controllers',controllers)}
 location.assign(origin);return;
}
 const duplicate=controllers.find(device=>device.host===host);
 if(duplicate){await selectController(duplicate.id);$('dialog-add-controller').close();toast('Ese controlador ya estaba guardado; lo seleccionamos');return}
 if(controllers.length>=16)throw Error('La demostración admite hasta 16 controladores guardados');
 const device={id:'demo_'+Date.now().toString(36)+'_'+Math.random().toString(36).slice(2,7),name,host};
 await api('state',undefined,device.id);
 controllers.push(device);persist('controllers',controllers);await selectController(device.id);
 $('dialog-add-controller').close();navigate('home');toast('Controlador simulado añadido');
});
$('customColor').oninput=()=>$('hexColor').value=$('customColor').value.toUpperCase();$('hexColor').oninput=()=>{if(/^#[a-fA-F0-9]{6}$/.test($('hexColor').value))$('customColor').value=$('hexColor').value};
onSubmit('colorForm',async()=>{const color=$('hexColor').value;if(!/^#[a-fA-F0-9]{6}$/.test(color))throw Error('Introduce un color como #B987D3');await sendLight({state:'ON',effect:'Color fijo',color:rgb(color)});$('dialog-color').close();toast('Tu color está aplicado')});
document.querySelectorAll('[data-minutes]').forEach(button=>button.onclick=()=>{$('timerMinutes').value=button.dataset.minutes;document.querySelectorAll('[data-minutes]').forEach(b=>b.setAttribute('aria-pressed',String(b===button)))});
$('timerMinutes').oninput=()=>document.querySelectorAll('[data-minutes]').forEach(b=>b.setAttribute('aria-pressed',String(b.dataset.minutes===$('timerMinutes').value)));
onSubmit('timerForm',async()=>{await api('timer',{minutes:Number($('timerMinutes').value),on:$('timerAction').value==='on'});await refresh();$('dialog-timer').close();toast('Cuenta atrás iniciada')});
$('cancelTimer').onclick=run(async()=>{await api('timer',{minutes:0});await refresh();$('dialog-timer').close();toast('Cuenta atrás cancelada')});
onSubmit('scheduleForm',async()=>{const days=Array.from(document.querySelectorAll('#scheduleDays input')).reduce((mask,input,i)=>mask|(input.checked?1<<i:0),0);if(!days)throw Error('Selecciona al menos un día');const schedules=cfg.schedules.map((s,i)=>i===editingSchedule?{enabled:$('scheduleEnabled').checked,time:$('scheduleTime').value,on:$('scheduleAction').value==='on',days}:{...s});await saveConfig({schedules});$('dialog-schedule').close();toast('Horario guardado')});
$('deleteSchedule').onclick=run(async()=>{await saveConfig({schedules:cfg.schedules.map((s,i)=>({...s,enabled:i===editingSchedule?false:s.enabled}))});$('dialog-schedule').close();toast('Horario desactivado')});
onSubmit('deviceForm',async()=>{const name=$('deviceName').value.trim();if(!name)throw Error('Escribe un nombre');await saveConfig({count:Number($('pixelCount').value),gpio:Number($('gpio').value),grb:$('colorOrder').value==='grb'});prefs.name=name;controllers=controllers.map(device=>device.id===selectedController?{...device,name}:device);persist('controllers',controllers);persist('name',name);renderState();renderSchedules();renderControllers();$('dialog-device').close();toast('Dispositivo guardado')});
onSubmit('wifiForm',async()=>{await saveConfig({ssid:$('wifiSsid').value,wifi_password:$('wifiPassword').value,clear_wifi_password:$('clearWifiPassword').checked});$('wifiPassword').value='';$('dialog-wifi').close();toast(isDemo?'Red guardada en la simulación':'Red guardada. Si cambia la IP, abre la nueva dirección o conecta a LEDWeb-…')});
onSubmit('mqttForm',async()=>{await saveConfig({mqtt_host:$('mqttHost').value.trim(),mqtt_port:Number($('mqttPort').value),mqtt_user:$('mqttUser').value,mqtt_password:$('mqttPassword').value,clear_mqtt_password:$('clearMqttPassword').checked});$('mqttPassword').value='';$('dialog-mqtt').close();toast(isDemo?'MQTT guardado en la simulación':'Configuración MQTT guardada; comprobando conexión')});
$('appearance').onchange=()=>{prefs.appearance=$('appearance').value;persist('appearance',prefs.appearance);theme()};
$('saveScene').onclick=run(()=>openSheet('scene'));
onSubmit('sceneForm',()=>{const name=$('sceneName').value.trim();if(!name)throw Error('Escribe un nombre');savedScenes=[...savedScenes,{id:Date.now().toString(),name,effect:current.effect,color:{...current.color},brightness:current.brightness,speed:current.speed}];persist('scenes',savedScenes);if(!favorites.includes(current.effect)){favorites.push(current.effect);persist('favorites',favorites)}renderHomeScenes();renderEffects();$('dialog-scene').close();toast('Ambiente guardado en favoritos')});
let initialized=false;
async function poll(){
 try{if(!initialized){await selectController(selectedController);initialized=true}else await refresh()}
 catch{connectionStatus(false)}
 finally{setTimeout(poll,document.hidden?10000:2500)}
}
document.addEventListener('visibilitychange',()=>{if(!document.hidden&&initialized)refresh().catch(()=>{})});
renderControllers();poll();
})();
