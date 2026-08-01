import { z } from 'zod';

export const createAdSchema = z.object({
  title: z.string().min(3, 'العنوان يجب أن يكون 3 أحرف على الأقل').max(200),
  price: z.number().positive('السعر يجب أن يكون أكبر من صفر'),
  location: z.string().min(2, 'الموقع مطلوب'),
  description: z.string().max(2000, 'الوصف طويل جداً').default('')
});
