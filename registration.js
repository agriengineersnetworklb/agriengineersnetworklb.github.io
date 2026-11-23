(() => {
  const config = window.AGRI_CONFIG || {}, form = document.querySelector('#registrationForm'), message = document.querySelector('#formMessage'), button = document.querySelector('#submitButton');
  const businessTypeInputs = [...form.querySelectorAll('[name="business_types"]')];
  const managedSelect=form.elements.managed_by_engineer,engineerName=form.elements.engineer_name;
  const syncEngineerRequirement=()=>{engineerName.required=managedSelect.value==='yes';if(!engineerName.required)engineerName.setCustomValidity('')};
  managedSelect.addEventListener('change',syncEngineerRequirement);syncEngineerRequirement();
  const validateBusinessTypes = () => {
    const selected = businessTypeInputs.some(field => field.checked);
    businessTypeInputs[0]?.setCustomValidity(selected ? '' : 'يرجى اختيار نوع نشاط واحد على الأقل.');
    return selected;
  };
  businessTypeInputs.forEach(field => field.addEventListener('change', validateBusinessTypes));
  const splitList = value => String(value || '').split(/[,،\n]/).map(x => x.trim()).filter(Boolean);
  const optional = value => String(value || '').trim() || null;
  const show = (text, type) => { message.textContent = text; message.className = `form-message ${type}`; message.scrollIntoView({behavior:'smooth',block:'center'}); };
  form.addEventListener('submit', async event => {
    event.preventDefault(); validateBusinessTypes(); if (!form.reportValidity()) return;
    if (!config.SUPABASE_URL || !config.SUPABASE_ANON_KEY) return show('تعذّر الاتصال بقاعدة البيانات. يرجى المحاولة لاحقاً.', 'error');
    const data = Object.fromEntries(new FormData(form).entries());
    const businessTypes = new FormData(form).getAll('business_types').map(String);
    const payload = {name:data.name.trim(),business_types:businessTypes,description:data.description_ar.trim(),description_ar:data.description_ar.trim(),description_en:data.description_en.trim(),year_established:optional(data.year_established),employees:optional(data.employees),governorate:data.governorate,district:data.district.trim(),town:data.town.trim(),address:optional(data.address),map_url:optional(data.map_url),multiple_locations:optional(data.multiple_locations),owner_name:data.contact_name.trim(),owner_whatsapp:data.whatsapp.trim(),contact_name:data.contact_name.trim(),position:optional(data.position),phone:data.phone.trim(),whatsapp:optional(data.whatsapp),email:data.email.trim(),website:optional(data.website),facebook:optional(data.facebook),instagram:optional(data.instagram),products_services:splitList(data.products_services),crops:splitList(data.crops),details:optional(data.details),logo_url:null,main_photo_url:null,additional_photos:[],managed_by_engineer:data.managed_by_engineer==='yes',engineer_name:optional(data.engineer_name),works_directly:optional(data.works_directly),delivery:optional(data.delivery),service_outside:optional(data.service_outside),areas_served:splitList(data.areas_served),online_available:optional(data.online_available),store_url:optional(data.store_url),consent:'Confirmed through portal registration',accuracy_confirmation:'Confirmed through portal registration',status:'pending',verified:false,reviewer_notes:''};
    button.disabled = true; button.textContent = 'جاري إرسال الطلب…'; message.className = 'form-message';
    try {
      const db = supabase.createClient(config.SUPABASE_URL,config.SUPABASE_ANON_KEY),upload=async file=>{if(!(file instanceof File)||!file.size)throw new Error('يرجى اختيار جميع الصور المطلوبة.');if(file.size>8*1024*1024)throw new Error('حجم كل صورة يجب ألا يتجاوز 8MB.');const ext=(file.name.split('.').pop()||'jpg').toLowerCase().replace(/[^a-z0-9]/g,''),path=`submissions/${Date.now()}-${Math.random().toString(36).slice(2)}.${ext}`,result=await db.storage.from('agri-media').upload(path,file,{contentType:file.type,upsert:false});if(result.error)throw result.error;return db.storage.from('agri-media').getPublicUrl(path).data.publicUrl};
      payload.logo_url=await upload(form.elements.logo_file.files[0]);
      payload.main_photo_url=await upload(form.elements.main_photo_file.files[0]);
      payload.additional_photos=[];
      for(const file of form.elements.additional_photos_files.files)payload.additional_photos.push(await upload(file));
      const {data:receipt,error}=await db.rpc('submit_listing',{payload});
      if(error) throw error;
      form.reset();
      show(`تم استلام الطلب والشعار والصور بنجاح. رقم المتابعة: ${receipt}. ستقوم إدارة الدليل بمراجعته قبل النشر. شكراً لمساهمتكم! 🌱`,'success');
    }
    catch(error) {
      console.error('Organization submission failed',error);
      const reference=error?.code?` (رمز الخطأ: ${error.code})`:'';
      show(`لم نتمكن من حفظ الطلب${reference}. الصور والمعلومات لن تُعتبر مسجلة قبل ظهور رقم المتابعة. يرجى المحاولة مجدداً أو التواصل مع الإدارة.`,'error');
    }
    finally { button.disabled=false; button.textContent='إرسال طلب التسجيل'; }
  });
})();
