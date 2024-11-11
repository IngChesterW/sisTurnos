const express = require('express');
const router  = express.Router();
const session = require('express-session');
const cors = require('cors');
const pool = require('../../keys2');
const pool2 = require('../../keys');
const fs = require('fs');
const os = require('os');
const path =require('path');
const archivoCalentura=('/sys/class/thermal/thermal_zone0/temp');
const {formatearFechaHora} = require('../../funcAux/funcionesAuxiliares');
const axios = require('axios');


//-------funcion---verificar----------tiempo------------->

function salioDelBaneo(fechaControl,fechaGet,min){
   let result= fechaGet - fechaControl ;
   console.log(fechaControl + '--------' + fechaGet);
   let resultado = result / (60*1000);
   console.log(resultado);
   return resultado > min ; 
};



//-------funcion-----adicionar-------llamadas-----con---verificacion------------->
 
async function adicionarVerificarLlamada(info){
    const {doctor,paciente,lugar} = info;
    const fecha = new Date();
    info.fecha = formatearFechaHora(fecha);
   //verificamos que no este duplicado 
   let verificar = await pool.query('select * from llamadas where doctor = ?  and paciente = ?  and lugar = ?',[doctor,paciente,lugar]);
   if (verificar[0].length === 0){
      await pool.query('insert into llamadas set ?',[info]);
      console.log('funciona verifica e inserta funcion');
   }else{
      console.log('funciona verifica y no inserta funcion');
   };
};


//------PANTALLA DE MUESTRA DE TURNOS----------------------------------------

router.get('/prueba/pantalla',async(req,res)=>{
    const servicio = session.hostName;     
	  //escuchamos cuando el front pregunta por la lista de llamadas
       socket.on('listarLlamadas',async()=>{
	     console.log('trae');
	     //await pool.query('delete from mensajes where UNIX_TIMESTAMP(`fechaMen`)<(UNIX_TIMESTAMP()-1800)');
	     await pool.query('delete from llamadas where UNIX_TIMESTAMP(`fecha`)<(UNIX_TIMESTAMP()-1800)');
       const  listaLlamadas = await pool.query('select * from llamadas ORDER BY codigo_llamada DESC LIMIT 5');
	     var llamadas = '';
	     if (listaLlamadas[0].length === 0){
                llamadas = 'vacio'; 
	     }else{
             //emitimos la lista de llamadas que acabamos de guardar en listaLlamadas
	     let  maxCodigoLlamada = Math.max(...listaLlamadas[0].map(item => item.codigo_llamada));
	         llamadas =  listaLlamadas[0].map((item) =>{
	      if(item.codigo_llamada === maxCodigoLlamada){
		     item.clase='ultima_caja';
		    
	      }else{
		     item.clase='caja';
		    
	      }
	    return item;
	  });
	   };
	     console.log(llamadas);
	     socket.emit('listaLlamadas',llamadas);
	  });

//configuraciones-------------------de----------------------videoVacio
 var listaVideosVacio = {};
 var  p = 0;
 let videosVacio = path.join(__dirname,'../../public/videos/');
 fs.readdir(videosVacio,(err,files)=>{
	 let x = 0;
	 files.forEach(file =>{
            console.log('video vacio bucle');
            x = x + 1;
	    p = p + 1;
	    console.log(file);
	    listaVideosVacio[x] = file;
            console.log(listaVideosVacio);	     
	 });
 });
 socket.on('videoVacioId',(idVidVac)=>{
    console.log('recibe id video vacio ' + idVidVac);
    if(idVidVac === '0' || idVidVac === null){
        let nuevoVid = {idVideo:1, src: listaVideosVacio[1]}; 
	socket.emit('nuevoVideoVacio',nuevoVid);
    }else{
      let auxi = Number(idVidVac);
      console.log(p);
        if(auxi < p ){
          auxi = auxi + 1;
          nuevoVid = {idVideo: auxi, src: listaVideosVacio[auxi]};
          socket.emit('nuevoVideoVacio',nuevoVid);
	}else{
          nuevoVid  = {idVideo : 1, src: listaVideosVacio[1]};
	  socket.emit('nuevoVideoVacio',nuevoVid);
	}
    }
 });

//configuraciones------------------- de---------------------  video
      let listaVideos ={};
      let a = 0;
      let videos = path.join(__dirname,'../../public/videos/');
      fs.readdir(videos,(err,files)=>{
	 let i = 0;
	 files.forEach(file =>{
         i= i+1;
	 a = a +1;
         listaVideos[i] = file;
	 });
	 });
      socket.on('video',(idVid)=>{
         if(idVid === '0'){
            let  nuevoVid = {idVideo : 1 , src: listaVideos[1]};
            io.emit('nuevoVideo',nuevoVid);
	 }else{
            let aux = Number(idVid);
	    if(aux < a){
	      aux = aux + 1;
	      nuevoVid = { idVideo : aux, src: listaVideos[aux]};
	      socket.emit('nuevoVideo',nuevoVid);
             }else{
	        nuevoVid = {idVideo:1, src: listaVideos[1]};
	       socket.emit('nuevoVideo',nuevoVid);
             };
	 };
      });
      
      
//listar------------mensajes-------------front-------------------------------->
 socket.on('listarMensajes',async ()=>{
 let mensajes = await pool.query('select * from mensajes');
     console.log(mensajes);
     mensajes = mensajes[0];
 var listaMensajes = ' ';
 var indice = 0;
       if (mensajes.length === 0){
	   console.log('entra');
           listaMensajes = 'vacio';
       }else{
       mensajes.forEach(mensaje =>{
                listaMensajes = (listaMensajes + ' ' + ' -  '  + [mensajes[0].mensaje]);
        	indice = indice + 1;
         });
       };	       
 socket.emit('listaMensajes',listaMensajes); 
 });
    

//render de views segun que servicio sea
 if(servicio){
   console.log('entra if');
   switch(servicio){
	   case  'consultorio' :
	     console.log('entra cons'); 
	     let  consultorio = 1;
             res.render('../views/index.hbs',{consultorio});
           break;
	   case  'imagenologia' :
	     console.log('entra imagenologia');
	     let  imagenologia = 1;
	     res.render('../views/index.hbs',{imagenologia});
           break;
	   case 'laboratorio' :
             let laboratorio = 1;
	     res.render('../views/index.hbs',{laboratorio});
	     break;
           case 'emergencia' :
             let emergencia = 1;
	     res.render('../views/index.hbs',{emergencia});
	     break;
   };
  }else{
	res.send('no se recibio el tipo de servicio');
  };
});


//registro---de----llamadas------------------------------>
router.get('/prueba/registroLlamadaGet',async(req,res)=>{
      const {doc,pac,lug} = req.query;
	//fecha en que se realiza el get (actual)
	let fechaGet = Date.now();
	//seteamos la fecha del get en sesion para comparar
	session.fechaGet= fechaGet;
	console.log(session.fechaGet + '--------' + session.fechaControl);
	let resultado = {};
	let fecha = new Date();
	    fecha = formatearFechaHora(fecha);
	let  info = {doctor:doc,paciente:pac,lugar:lug};
        //preguntamos si ya se configurÃ³ una fecha de control (primer registro del doctor)
	      if(session.fechaControl){
                  //preguntamos si desde la fecha de control han pasado 2 minutos desde la fechaGet (primer registro)
	          if(session.fechaControl,session.fechaGet){         
		       session.fechaControl = session.fechaGet;
		       adicionarVerificarLlamada(info);
		       req.flash('message',info);
		       resultado.mensaje = 'a primeira chamada foi cadastrada com suceso';
	           }else{
		      //todavia baneado por tiempo 
	               console.log('el doctor ' + doc + ' o el consultorio ' + lug + ' estan baneados todavia');
		       resultado.mensaje = 'ainda banido pelo tempo ';
		   };
	        }else {
		  //primer get, entonces registramos la fecha y hacemos la insercion
                  session.fechaControl = session.fechaGet;
		  info.fecha = fecha;
	          await pool.query('insert into llamadas set ?',[info]);
	          resultado.mensaje = ' chamada de cotrole cadastrada com suceso';
        	}
	//emitimos el evento para  mostrar lista llamadas  en pantalla en tiempo real
       io.emit('nuevaLlamada',info);
       //resultado para testing de rest
	res.send('resultado');
});

//--------------------------------------------------------------
router.get('/opciones/:opcion', async(req,res)=>{
	 const {opcion} = req.params;
	 switch (opcion) {
	  case  'eliminarLlamadas' :
 	    await pool.query('delete from llamadas');
	    io.emit('sinLlamadas');
            res.send('se eliminaron las llamadas');
         break;
          case  'eliminarMensaje':
	    await pool.query('delete from mensajes');
            res.send('se elimino mensajes');
	    io.emit('sinMensajes');
	  break;
          case 'adicionarMensaje':
	    await pool.query(`insert into mensajes(mensaje) values('dasdasdasdasdasdasdasdasdasdasdasd122314')`);
            res.send('adicionado mensaje');
	    io.emit('nuevoMensaje');
        };
});




return router;

