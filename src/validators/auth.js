import { z } from 'zod';

export const registerSchema = z.object({
  name: z.string().min(2, 'الاسم يجب أن يكون حرفين على الأقل').max(50, 'الاسم طويل جداً'),
  email: z.string().email('البريد الإلكتروني غير صالح'),
  phone: z.string().regex(/^(\+966|0)?5\d{8}$/, 'رقم الجوال غير صالح (مثال: 05xxxxxxxx)'),
  password: z.string().min(6, 'كلمة المرور يجب أن تكون 6 أحرف على الأقل').max(100)
});

export const loginSchema = z.object({
  email: z.string().email('البريد الإلكتروني غير صالح'),
  password: z.string().min(1, 'كلمة المرور مطلوبة')
});

export const refreshSchema = z.object({
  refreshToken: z.string().min(1, 'Refresh token مطلوب')
});

export const profileUpdateSchema = z.object({
  name: z.string().min(2).max(50).optional(),
  phone: z.string().regex(/^(\+966|0)?5\d{8}$/, 'رقم الجوال غير صالح').optional(),
  avatar: z.string().url().optional().or(z.literal(''))
});
