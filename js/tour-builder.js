/* أتمتة الجولات الافتراضية 360 — تحويل الصور العادية إلى بانوراما Equirectangular تفاعلية */
var tbResults=[];
var tbFiles=[];

function openTourBuilder(){
  if(window.nav)nav('tour');
  var pg=document.getElementById('pg-tour');
  if(!pg)return;
  var list=document.getElementById('tbList');
  if(list&&!tbFiles.length&&!tbResults.length){
    list.innerHTML='<div style="padding:26px 14px;text-align:center;color:var(--m);font-size:13px;line-height:2">أضف صور الموقع (غرف، واجهة، حديقة…)<br>وسيقوم المحرك بتحويلها تلقائيًا إلى مشاهد بانورامية 360° قابلة للسحب</div>';
  }
}

function tbAddFiles(files){
  var list=document.getElementById('tbList');
  for(var i=0;i<files.length;i++){
    var f=files[i];
    if(!/^image\//.test(f.type))continue;
    var reader=new FileReader();
    reader.onload=(function(ff){
      return function(ev){
        tbFiles.push({file:ff,url:ev.target.result,name:ff.name||('صورة '+(tbFiles.length+1))});
        var div=document.createElement('div');
        div.className='tb-file';
        div.innerHTML='<img src="'+ev.target.result+'"><div class="tb-file-info"><div class="tb-file-n">'+esc(ff.name||'صورة')+'</div><div class="tb-file-s">'+(ff.size/1024>1024?(ff.size/1048576).toFixed(1)+' MB':Math.round(ff.size/1024)+' KB')+'</div></div><div class="tb-file-x" onclick="tbRemoveFile(this)">✕</div>';
        list.appendChild(div);
        document.getElementById('tbEmpty').style.display='none';
        document.getElementById('tbGen').style.display='';
      };
    })(f);
    reader.readAsDataURL(f);
  }
}

function tbRemoveFile(el){
  var div=el.parentNode;
  var idx=[].indexOf.call(div.parentNode.children,div);
  var f=tbFiles[idx];
  div.parentNode.removeChild(div);
  if(f&&f.url&&f.url.indexOf('data:')===0){try{URL.revokeObjectURL(f.url)}catch(e){}}
  tbFiles.splice(idx,1);
  var list=document.getElementById('tbList');
  if(!tbFiles.length&&!tbResults.length){
    document.getElementById('tbEmpty').style.display='';
    document.getElementById('tbGen').style.display='none';
    list.innerHTML='<div style="padding:26px 14px;text-align:center;color:var(--m);font-size:13px;line-height:2">أضف صور الموقع (غرف، واجهة، حديقة…)<br>وسيقوم المحرك بتحويلها تلقائيًا إلى مشاهد بانورامية 360° قابلة للسحب</div>';
  }
}

function tbDrop(ev){
  ev.preventDefault();
  if(ev.dataTransfer&&ev.dataTransfer.files.length)tbAddFiles(ev.dataTransfer.files);
}

function imgToEquirect(img,hfovDeg,outW){
  var outH=Math.round(outW/2);
  var iw=img.naturalWidth||img.width,ih=img.naturalHeight||img.height;
  var vfovDeg=hfovDeg*(ih/iw);
  var cv=document.createElement('canvas');cv.width=outW;cv.height=outH;
  var ctx=cv.getContext('2d');
  var halfH=hfovDeg/2,halfV=vfovDeg/2;
  var scale=Math.max(outW/iw,outH/ih);
  var w=iw*scale,h=ih*scale;
  if(ctx.filter){
    ctx.filter='blur('+Math.max(18,Math.round(outW/50))+'px)';
    ctx.drawImage(img,(outW-w)/2,(outH-h)/2,w,h);
    ctx.filter='none';
  }else{
    ctx.drawImage(img,(outW-w)/2,(outH-h)/2,w,h);
  }
  ctx.fillStyle='rgba(8,9,12,.35)';
  ctx.fillRect(0,0,outW,outH);
  var id=ctx.getImageData(0,0,outW,outH),d=id.data;
  var iX=iw-1,iY=ih-1;
  for(var y=0;y<outH;y++){
    var pitch=90-(y/outH)*180;
    if(pitch>halfV||pitch<-halfV)continue;
    var fy=(halfV-pitch)/(2*halfV)*ih;
    var fy0=Math.max(0,Math.min(iY,Math.floor(fy)));
    var fy1=Math.min(iY,fy0+1);
    var wy=fy-fy0;
    for(var x=0;x<outW;x++){
      var yaw=(x/outW)*360-180;
      if(Math.abs(yaw)>halfH)continue;
      var fx=(yaw+halfH)/(2*halfH)*iw;
      var fx0=Math.max(0,Math.min(iX,Math.floor(fx)));
      var fx1=Math.min(iX,fx0+1);
      var wx=fx-fx0;
      var s00=(fy0*iw+fx0)*4,s01=(fy0*iw+fx1)*4,s10=(fy1*iw+fx0)*4,s11=(fy1*iw+fx1)*4;
      var r=(d[s00]*(1-wx)+d[s01]*wx)*(1-wy)+(d[s10]*(1-wx)+d[s11]*wx)*wy;
      var g=(d[s00+1]*(1-wx)+d[s01+1]*wx)*(1-wy)+(d[s10+1]*(1-wx)+d[s11+1]*wx)*wy;
      var b=(d[s00+2]*(1-wx)+d[s01+2]*wx)*(1-wy)+(d[s10+2]*(1-wx)+d[s11+2]*wx)*wy;
      var di=(y*outW+x)*4;
      d[di]=r;d[di+1]=g;d[di+2]=b;d[di+3]=255;
    }
  }
  ctx.putImageData(id,0,0);
  return cv;
}

function loadImage(url){
  return new Promise(function(res,rej){
    var img=new Image();
    img.onload=function(){res(img)};
    img.onerror=function(){rej(new Error('تعذر تحميل الصورة'))};
    img.src=url;
  });
}

async function tbGenerate(){
  if(!tbFiles.length){toast('أضف صورًا أولًا');return}
  var hfov=parseInt(document.getElementById('tbHfov').value,10);
  var outW=parseInt(document.getElementById('tbQual').value,10);
  var bar=document.getElementById('tbBarWrap');
  var fill=document.getElementById('tbBar');
  var status=document.getElementById('tbStatus');
  var btn=document.getElementById('tbGen');
  btn.style.display='none';
  bar.style.display='block';
  status.style.display='';
  tbResults=[];
  var resWrap=document.getElementById('tbResults');
  resWrap.innerHTML='';
  resWrap.style.display='block';
  try{
    for(var i=0;i<tbFiles.length;i++){
      status.textContent='⏳ تحويل «'+(tbFiles[i].name||('صورة '+(i+1)))+'»... ('+(i+1)+'/'+tbFiles.length+')';
      fill.style.width=(i/tbFiles.length*100)+'%';
      await new Promise(function(r){setTimeout(r,30)});
      var img=await loadImage(tbFiles[i].url);
      var cv=imgToEquirect(img,hfov,outW);
      var dataUrl=cv.toDataURL('image/jpeg',0.86);
      tbResults.push({dataUrl:dataUrl,name:tbFiles[i].name||('صورة '+(i+1))});
      var card=document.createElement('div');
      card.className='tb-result';
      card.innerHTML='<img src="'+dataUrl+'" alt="بانوراما '+(i+1)+'"><div class="tb-result-n">🌐 '+(tbFiles[i].name||('مشهد '+(i+1)))+'</div><div class="tb-result-actions"><button onclick="tbPreviewOne('+i+')">معاينة</button><a download="pano-360-'+(i+1)+'.jpg" href="'+dataUrl+'">⬇ تحميل</a></div>';
      resWrap.appendChild(card);
      fill.style.width=((i+1)/tbFiles.length*100)+'%';
    }
    status.textContent='✅ تم تحويل '+tbResults.length+' صورة إلى بانوراما 360°';
    document.getElementById('tbActions').style.display='flex';
    toast('تم توليد الجولة البانورامية ✓');
  }catch(e){
    status.textContent='❌ '+e.message;
    toast(e.message);
  }
  bar.style.display='none';
  btn.style.display='';
}

function tbPreviewAll(){
  if(!tbResults.length){toast('قُم بالتوليد أولًا');return}
  currentDetail={};
  window.vrForcePano=true;
  openVR(tbResults.map(function(r){return r.dataUrl}),tbResults.map(function(r,i){return'مشهد '+(i+1)}));
}

function tbPreviewOne(idx){
  if(!tbResults.length||!tbResults[idx])return;
  currentDetail={};
  window.vrForcePano=true;
  openVR([tbResults[idx].dataUrl],[tbResults[idx].name||('مشهد '+(idx+1))]);
}

function tbDownloadAll(){
  if(!tbResults.length){toast('قُم بالتوليد أولًا');return}
  tbResults.forEach(function(r,i){
    var a=document.createElement('a');
    a.href=r.dataUrl;a.download='pano-360-'+(i+1)+'.jpg';
    document.body.appendChild(a);a.click();
    setTimeout(function(){a.parentNode.removeChild(a)},200);
  });
}

function esc(s){
  return String(s==null?'':s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}

async function tbPreload(urls){
  if(!urls||!urls.length){toast('لا توجد صور');return}
  if(typeof closeD==='function')closeD();
  openTourBuilder();
  var loaded=0;
  for(var i=0;i<urls.length;i++){
    try{
      var r=await fetch(urls[i]);
      if(!r.ok)continue;
      var b=await r.blob();
      if(!/^image\//.test(b.type))continue;
      tbAddFiles([new File([b],'صورة '+(i+1),{type:b.type})]);
      loaded++;
    }catch(e){}
  }
  if(!loaded){toast('تعذر جلب الصور تلقائيًا — ارفعها يدويًا');return}
  toast('تم جلب '+loaded+' صورة — اضغط «توليد الجولة»');
}

var autoPanoDataUrl=null,autoPanoBlob=null;
function addImgAuto360(input){
  var preview=document.getElementById('ap-img-preview');
  var files=input.files||[];
  preview.innerHTML='';
  if(!files.length)return;
  for(var i=0;i<files.length;i++){
    var f=files[i];
    if(!/^image\//.test(f.type))continue;
    var url=URL.createObjectURL(f);
    var el=document.createElement('div');
    el.className='ap-img-thumb';
    el.innerHTML='<img src="'+url+'">';
    preview.appendChild(el);
  }
  var first=null;
  for(var i2=0;i2<files.length;i2++){if(/^image\//.test(files[i2].type)){first=files[i2];break}}
  if(!first)return;
  var box=document.getElementById('ap-auto360');
  if(box){box.style.display='none';box.innerHTML='<div style="font-size:12px;font-weight:800;color:var(--g)">⏳ جاري برمجة الجولة 360 من صورتك...</div>'}
  fileToEquirect(first,110,1280).then(function(res){
    autoPanoDataUrl=res.dataUrl;autoPanoBlob=res.blob;
    if(box){
      box.innerHTML='<div style="font-size:12px;font-weight:800;color:#4ade80">✅ تم برمجة الجولة 360 من صورتك</div><div style="font-size:11px;color:var(--m);margin-top:4px;line-height:1.8">ستظهر للزوار كجولة تفاعلية قابلة للسحب. يمكنك معاينتها الآن.</div><button class="tb-tour3d-b" onclick="apPreviewTour()">🎬 معاينة الجولة المولّدة</button>';
      box.style.display='block';
    }
    toast('تم توليد الجولة من صورتك ✓');
  }).catch(function(e){
    if(box){
      box.innerHTML='<div style="font-size:12px;font-weight:800;color:#f87171">⚠️ تعذر توليد الجولة من الصورة</div><div style="font-size:11px;color:var(--m);margin-top:4px">'+e.message+'</div>';
      box.style.display='block';
    }
  });
}
function fileToEquirect(file,hfov,outW){
  return new Promise(function(res,rej){
    var reader=new FileReader();
    reader.onload=function(ev){
      var img=new Image();
      img.onload=function(){
        try{
          var cv=imgToEquirect(img,hfov,outW);
          var dataUrl=cv.toDataURL('image/jpeg',0.86);
          cv.toBlob(function(b){res({dataUrl:dataUrl,blob:b||null})},'image/jpeg',0.86);
        }catch(e){rej(e)}
      };
      img.onerror=function(){rej(new Error('صورة غير صالحة'))};
      img.src=ev.target.result;
    };
    reader.onerror=function(){rej(new Error('تعذر قراءة الملف'))};
    reader.readAsDataURL(file);
  });
}
function apPreviewTour(){
  if(!autoPanoDataUrl){toast('ارفع صورة أولًا');return}
  currentDetail={};
  window.vrForcePano=true;
  openVR([autoPanoDataUrl],['جولتي']);
}

function tbOpenTour3D(){
  var url=(document.getElementById('tbTourUrl')||{}).value||'';
  url=url.trim();
  if(!url){toast('الصق رابط الجولة أولًا');return}
  if(!/^https?:\/\//i.test(url)){
    toast('رابط غير صالح — يجب أن يبدأ بـ http:// أو https://');
    return;
  }
  vrTourOpen(url);
}
