(() => {
  const config = window.AGRI_CONFIG || {}, form = document.querySelector('#registrationForm'), message = document.querySelector('#formMessage'), button = document.querySelector('#submitButton');
  const splitList = value => String(value || '').split(/[,،\n]/).map(x => x.trim()).filter(Boolean);
  const optional = value => String(value || '').trim() || null;
  const packDescriptions = (ar,en) => `[[AR]]\n${ar}\n[[EN]]\n${en}`;
  const show = (text, type) => { message.textContent = text; message.className = `form-message ${type}`; message.scrollIntoView({behavior:'smooth',block:'center'}); };
  form.addEventListener('submit', async event => {
    event.preventDefault(); if (!form.reportValidity()) return;
    if (!form.querySelector('[name="business_types"]:checked')) return show('يرجى اختيار نوع نشاط واحد على الأقل.', 'error');
    if (!config.SUPABASE_URL || !config.SUPABASE_ANON_KEY) return show('تعذّر الاتصال بقاعدة البيانات. يرجى المحاولة لاحقاً.', 'error');
    const data = Object.fromEntries(new FormData(form).entries());
    const businessTypes = new FormData(form).getAll('business_types').map(String);
    const payload = {name:data.name.trim(),business_types:businessTypes,description:data.description_ar.trim(),description_ar:data.description_ar.trim(),description_en:data.description_en.trim(),year_established:optional(data.year_established),employees:optional(data.employees),governorate:data.governorate,district:data.district.trim(),town:data.town.trim(),address:optional(data.address),map_url:optional(data.map_url),owner_name:data.owner_name.trim(),owner_whatsapp:data.owner_whatsapp.trim(),contact_name:data.contact_name.trim(),position:optional(data.position),phone:data.phone.trim(),whatsapp:optional(data.whatsapp),email:data.email.trim(),website:optional(data.website),facebook:optional(data.facebook),instagram:optional(data.instagram),products_services:splitList(data.products_services),crops:splitList(data.crops),details:optional(data.details),logo_url:null,main_photo_url:optional(data.main_photo_url),managed_by_engineer:data.managed_by_engineer==='yes',engineer_name:optional(data.engineer_name),delivery:optional(data.delivery),service_outside:optional(data.service_outside),areas_served:splitList(data.areas_served),online_available:optional(data.online_available),store_url:optional(data.store_url),consent:'Confirmed through portal registration',accuracy_confirmation:'Confirmed through portal registration',status:'pending',verified:false,reviewer_notes:''};
    button.disabled = true; button.textContent = 'جاري إرسال الطلب…'; message.className = 'form-message';
    try { const db = supabase.createClient(config.SUPABASE_URL,config.SUPABASE_ANON_KEY); let {error} = await db.from('listings').insert(payload); if(error?.code==='PGRST204'||error?.code==='42703'){const legacy={...payload,description:packDescriptions(payload.description_ar,payload.description_en)};delete legacy.description_ar;delete legacy.description_en;({error}=await db.from('listings').insert(legacy))} if(error) throw error; form.reset(); show('تم استلام طلبكم بنجاح. ستقوم إدارة الدليل بمراجعته قبل النشر. شكراً لمساهمتكم! 🌱','success'); }
    catch(error) { console.error(error); show('لم نتمكن من إرسال الطلب حالياً. يرجى التأكد من البيانات والمحاولة مجدداً.','error'); }
    finally { button.disabled=false; button.textContent='إرسال طلب التسجيل'; }
  });
})();
