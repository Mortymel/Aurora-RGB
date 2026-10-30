/* Same-origin requests: the ESP32 owns authentication; no passwords in storage. */
(function(root){
  'use strict';
  function createTransport({demo=false,fetchImpl=root.fetch.bind(root),timeout=8000}={}){
    return async function(path,data,deviceId='default'){
      const abort=new AbortController();
      const timer=setTimeout(()=>abort.abort(),timeout);
      try{
        const response=await fetchImpl('/api/'+path,{
          signal:abort.signal,credentials:'same-origin',cache:'no-store',
          headers:{'Content-Type':'application/json',...(demo?{'X-Demo-Device':deviceId}:{})},
          ...(data===undefined?{}:{method:'POST',body:JSON.stringify(data)})
        });
        if(response.status===401)throw Error('Sesión no autorizada. Recarga la página e introduce el usuario y la clave del controlador.');
        let value;try{value=await response.json()}catch{throw Error('El controlador no devolvió una respuesta válida.')}
        if(!response.ok)throw Error(value.error||'No se pudo completar la acción ('+response.status+').');
        return value;
      }catch(error){
        if(error.name==='AbortError')throw Error('El controlador no responde. Comprueba la alimentación y la conexión Wi-Fi.');
        if(error instanceof TypeError)throw Error('Sin conexión con el controlador. Comprueba que estés en su misma red.');
        throw error;
      }finally{clearTimeout(timer)}
    };
  }
  function controllerAddress(value){
    let url;try{url=new URL(value.includes('://')?value.trim():'http://'+value.trim())}catch{throw Error('Introduce una IP o nombre .local válido')}
    if(!['http:','https:'].includes(url.protocol)||url.username||url.password||url.search||url.hash||url.pathname!=='/'||!url.hostname.includes('.'))throw Error('Introduce solo la dirección del controlador');
    return url.origin;
  }
  const api={createTransport,controllerAddress};
  if(typeof module==='object'&&module.exports)module.exports=api;else root.AuroraTransport=api;
})(globalThis);
