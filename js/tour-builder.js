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
  var src=document.createElement('canvas');
  src.width=iw;src.height=ih;
  var sctx=src.getContext('2d');
  sctx.drawImage(img,0,0);
  var sd=sctx.getImageData(0,0,iw,ih).data;
  var cv=document.createElement('canvas');cv.width=outW;cv.height=outH;
  var ctx=cv.getContext('2d');
  var halfH=hfovDeg/2,halfV=vfovDeg/2,backSpan=180-halfH;
  var id=ctx.getImageData(0,0,outW,outH),d=id.data;
  var iX=iw-1,iY=ih-1,topY=0,botY=ih-1;
  for(var y=0;y<outH;y++){
    var pitch=90-(y/outH)*180;
    var fy=(halfV-pitch)/(2*halfV)*ih;
    var fy0=Math.max(0,Math.min(iY,Math.floor(fy)));
    var fy1=Math.min(iY,fy0+1);
    var wy=fy-fy0;
    for(var x=0;x<outW;x++){
      var yaw=(x/outW)*360-180;
      var ax=Math.abs(yaw);
      var di=(y*outW+x)*4;
      var sx,k=1;
      if(ax<=halfH){
        sx=(yaw+halfH)/(2*halfH)*iw;
      }else{
        var t=(ax-halfH)/backSpan;
        sx=(yaw>0)?iw*(1-t):iw*t;
        k=1-0.6*t;
      }
      var fx0=Math.max(0,Math.min(iX,Math.floor(sx)));
      var fx1=Math.min(iX,fx0+1);
      var wx=sx-fx0;
      var r,g,b;
      if(pitch>halfV){
        var s=(topY*iw+fx0)*4;
        var up=Math.min(1,(pitch-halfV)/(90-halfV));
        r=sd[s]*(1-up*0.35);g=sd[s+1]*(1-up*0.35);b=sd[s+2]*(1-up*0.35);
      }else if(pitch<-halfV){
        var s2=(botY*iw+fx0)*4;
        var dn=Math.min(1,(-pitch-halfV)/(90-halfV));
        r=sd[s2]*(1-dn*0.55);g=sd[s2+1]*(1-dn*0.55);b=sd[s2+2]*(1-dn*0.55);
      }else{
        var s00=(fy0*iw+fx0)*4,s01=(fy0*iw+fx1)*4,s10=(fy1*iw+fx0)*4,s11=(fy1*iw+fx1)*4;
        r=(sd[s00]*(1-wx)+sd[s01]*wx)*(1-wy)+(sd[s10]*(1-wx)+sd[s11]*wx)*wy;
        g=(sd[s00+1]*(1-wx)+sd[s01+1]*wx)*(1-wy)+(sd[s10+1]*(1-wx)+sd[s11+1]*wx)*wy;
        b=(sd[s00+2]*(1-wx)+sd[s01+2]*wx)*(1-wy)+(sd[s10+2]*(1-wx)+sd[s11+2]*wx)*wy;
      }
      d[di]=r*k;d[di+1]=g*k;d[di+2]=b*k;d[di+3]=255;
    }
  }
  ctx.putImageData(id,0,0);
  return cv;
}

function equirectMulti(imgs,outW){
  var outH=Math.round(outW/2);
  var N=imgs.length;
  if(N<1)return null;
  if(N===1)return imgToEquirect(imgs[0],150,outW);
  var list=[];
  for(var i=0;i<N;i++){
    var img=imgs[i];
    var iw=img.naturalWidth||img.width,ih=img.naturalHeight||img.height;
    var c=document.createElement('canvas');c.width=iw;c.height=ih;
    c.getContext('2d').drawImage(img,0,0);
    var slice=360/N;
    var halfV=Math.min(50,slice*(ih/iw)/2);
    list.push({iw:iw,ih:ih,data:c.getContext('2d').getImageData(0,0,iw,ih).data,halfV:halfV});
  }
  var out=document.createElement('canvas');out.width=outW;out.height=outH;
  var octx=out.getContext('2d');
  var oid=octx.getImageData(0,0,outW,outH),od=oid.data;
  var sliceDeg=360/N;
  var pixAt=function(idx,tt,pitch){
    var o=list[idx],iw=o.iw,ih=o.ih,sd=o.data,iX=iw-1,iY=ih-1;
    if(tt<0)tt=0;if(tt>1)tt=1;
    var fx=tt*iw;
    var fx0=Math.max(0,Math.min(iX,Math.floor(fx))),fx1=Math.min(iX,fx0+1),wx=fx-fx0;
    var halfV=o.halfV;
    if(pitch>halfV){
      var up=Math.min(1,(pitch-halfV)/(90-halfV));
      var s=(0*iw+fx0)*4;
      return [sd[s]*(1-up*0.35),sd[s+1]*(1-up*0.35),sd[s+2]*(1-up*0.35)];
    }
    if(pitch<-halfV){
      var dn=Math.min(1,(-pitch-halfV)/(90-halfV));
      var s2=((ih-1)*iw+fx0)*4;
      return [sd[s2]*(1-dn*0.55),sd[s2+1]*(1-dn*0.55),sd[s2+2]*(1-dn*0.55)];
    }
    var fy=(halfV-pitch)/(2*halfV)*ih;
    var fy0=Math.max(0,Math.min(iY,Math.floor(fy))),fy1=Math.min(iY,fy0+1),wy=fy-fy0;
    var s00=(fy0*iw+fx0)*4,s01=(fy0*iw+fx1)*4,s10=(fy1*iw+fx0)*4,s11=(fy1*iw+fx1)*4;
    var r=(sd[s00]*(1-wx)+sd[s01]*wx)*(1-wy)+(sd[s10]*(1-wx)+sd[s11]*wx)*wy;
    var g=(sd[s00+1]*(1-wx)+sd[s01+1]*wx)*(1-wy)+(sd[s10+1]*(1-wx)+sd[s11+1]*wx)*wy;
    var b=(sd[s00+2]*(1-wx)+sd[s01+2]*wx)*(1-wy)+(sd[s10+2]*(1-wx)+sd[s11+2]*wx)*wy;
    return [r,g,b];
  };
  for(var y=0;y<outH;y++){
    var pitch=90-(y/outH)*180;
    for(var x=0;x<outW;x++){
      var yaw=(x/outW)*360-180;
      var di=(y*outW+x)*4;
      var i0=Math.floor((yaw+180)/sliceDeg);
      if(i0>=N)i0=N-1;
      var start=-180+i0*sliceDeg;
      var t=(yaw-start)/sliceDeg;
      var B=0.1;
      var col;
      if(t<B&&N>1){
        var prev=(i0-1+N)%N;
        var p1=pixAt(prev,1-(B-t)/(2*B),pitch);
        var p2=pixAt(i0,t/B,pitch);
        var w=t/B;
        col=[p1[0]*(1-w)+p2[0]*w,p1[1]*(1-w)+p2[1]*w,p1[2]*(1-w)+p2[2]*w];
      }else if(t>1-B&&N>1){
        var nxt=(i0+1)%N;
        var p1=pixAt(i0,(1-t)/B,pitch);
        var p2=pixAt(nxt,(B-(1-t))/B,pitch);
        var w=(1-t)/B;
        col=[p1[0]*(1-w)+p2[0]*w,p1[1]*(1-w)+p2[1]*w,p1[2]*(1-w)+p2[2]*w];
      }else{
        col=pixAt(i0,t,pitch);
      }
      od[di]=col[0];od[di+1]=col[1];od[di+2]=col[2];od[di+3]=255;
    }
  }
  octx.putImageData(oid,0,0);
  return out;
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
    var mb=document.getElementById('tbMerge');
    if(mb)mb.style.display=(tbFiles.length>1)?'block':'none';
    toast('تم توليد الجولة البانورامية ✓');
  }catch(e){
    status.textContent='❌ '+e.message;
    toast(e.message);
  }
  bar.style.display='none';
  btn.style.display='';
}

async function tbMergeAll(){
  if(tbFiles.length<2){toast('أضف صورتين على الأقل للدمج');return}
  var outW=parseInt(document.getElementById('tbQual').value,10);
  var btn=document.getElementById('tbMerge');
  if(btn)btn.disabled=true;
  try{
    var imgs=[];
    for(var i=0;i<tbFiles.length;i++){
      imgs.push(await loadImage(tbFiles[i].url));
    }
    var cv=equirectMulti(imgs,outW);
    if(!cv)throw new Error('تعذر الدمج');
    var dataUrl=cv.toDataURL('image/jpeg',0.88);
    tbResults.unshift({dataUrl:dataUrl,name:'🧩 جولة 360 كاملة ('+imgs.length+' صور)'});
    var resWrap=document.getElementById('tbResults');
    resWrap.style.display='block';
    resWrap.insertAdjacentHTML('afterbegin','<div class="tb-result"><img src="'+dataUrl+'" alt="جولة 360 كاملة"><div class="tb-result-n">🌐 🧩 جولة 360 كاملة ('+imgs.length+' اتجاهات)</div><div class="tb-result-actions"><button onclick="tbPreviewOne(0)">معاينة</button><a download="pano-360-merged.jpg" href="'+dataUrl+'">⬇ تحميل</a></div></div>');
    toast('تم دمج الصور في جولة 360 كاملة ✓');
  }catch(e){
    toast(e.message);
  }
  if(btn)btn.disabled=false;
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
  var imgsFiles=[];
  for(var i2=0;i2<files.length;i2++){if(/^image\//.test(files[i2].type)){imgsFiles.push(files[i2]);if(!first)first=files[i2]}}
  if(!first)return;
  var box=document.getElementById('ap-auto360');
  if(box){box.style.display='none';box.innerHTML='<div style="font-size:12px;font-weight:800;color:var(--g)">⏳ جاري برمجة الجولة 360 من صورك...</div>'}
  filesToEquirect(imgsFiles).then(function(res){
    autoPanoDataUrl=res.dataUrl;autoPanoBlob=res.blob;
    if(box){
      box.innerHTML='<div style="font-size:12px;font-weight:800;color:#4ade80">✅ تم برمجة الجولة 360'+(imgsFiles.length>1?' من '+imgsFiles.length+' صور (تغطي كل الاتجاهات)':' من صورتك')+'</div><div style="font-size:11px;color:var(--m);margin-top:4px;line-height:1.8">ستظهر للزوار كجولة تفاعلية قابلة للسحب 360°. يمكنك معاينتها الآن.</div><button class="tb-tour3d-b" onclick="apPreviewTour()">🎬 معاينة الجولة المولّدة</button>';
      box.style.display='block';
    }
    toast('تم توليد الجولة 360 ✓');
  }).catch(function(e){
    if(box){
      box.innerHTML='<div style="font-size:12px;font-weight:800;color:#f87171">⚠️ تعذر توليد الجولة من الصور</div><div style="font-size:11px;color:var(--m);margin-top:4px">'+e.message+'</div>';
      box.style.display='block';
    }
  });
}
function filesToEquirect(files){
  return new Promise(function(res,rej){
    var imgs=[];
    var readers=files.map(function(f){
      return new Promise(function(r2,rej2){
        var reader=new FileReader();
        reader.onload=function(ev){
          var img=new Image();
          img.onload=function(){imgs.push(img);r2()};
          img.onerror=function(){rej2(new Error('صورة غير صالحة'))};
          img.src=ev.target.result;
        };
        reader.onerror=function(){rej2(new Error('تعذر قراءة الصور'))};
        reader.readAsDataURL(f);
      });
    });
    Promise.all(readers).then(function(){
      try{
        var cv=(imgs.length>1)?equirectMulti(imgs,2048):imgToEquirect(imgs[0],130,2048);
        var dataUrl=cv.toDataURL('image/jpeg',0.88);
        cv.toBlob(function(b){res({dataUrl:dataUrl,blob:b||null})},'image/jpeg',0.88);
      }catch(e){rej(e)}
    }).catch(rej);
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

var apVideoUrl=null;
function apVideoUploaded(input){
  var st=document.getElementById('ap-video-state');
  var f=input&&input.files&&input.files[0];
  if(!f){if(st)st.textContent='';return}
  if(st)st.textContent='⏳ جاري الرفع والتحويل إلى رابط مباشر...';
  var fd=new FormData();fd.append('file',f);
  fetch('https://upload.gofile.io/uploadfile',{method:'POST',body:fd})
    .then(function(r){return r.json()})
    .then(function(d){
      if(!(d&&d.status==='ok'&&d.data))throw new Error('فشل الرفع');
      return apResolveGofile(d.data).then(function(direct){
        var url=direct||d.data.downloadPage;
        apVideoUrl=url;
        var u=document.getElementById('ap-video-url');
        if(u)u.value=url;
        if(st)st.textContent=direct?'✅ تم — رابط مباشر جاهز':'✅ تم الرفع — الرابط أدناه';
        toast('تم رفع الفيديو وتحويله إلى رابط مباشر ✓');
      });
    })
    .catch(function(){
      apVideoUrl=null;
      if(st)st.textContent='⚠️ تعذر الرفع — الصق رابطًا مباشرًا';
      toast('تعذر رفع الفيديو — الصق رابط يوتيوب/MP4 مباشر');
    });
}
function apResolveGofile(d){
  if(!d||!d.parentFolderCode||!d.guestToken)return Promise.resolve(null);
  return fetch('https://api.gofile.io/getContent?contentId='+d.parentFolderCode+'&token='+d.guestToken)
    .then(function(r){return r.json()})
    .then(function(j){
      if(j&&j.status==='ok'&&j.data&&j.data.contents){
        var c=Object.keys(j.data.contents).map(function(k){return j.data.contents[k]})[0];
        if(c&&c.link)return c.link;
      }
      return null;
    })
    .catch(function(){return null});
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
