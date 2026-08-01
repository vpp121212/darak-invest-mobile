import { z } from 'zod';

export const createInvoiceSchema = z.object({
  type: z.string().min(1, 'نوع الفاتورة مطلوب'),
  amount: z.number().positive('المبلغ يجب أن يكون أكبر من صفر'),
  description: z.string().max(2000).optional().default(''),
  clientName: z.string().max(100).optional().default(''),
  clientPhone: z.string().optional().default(''),
  propertyId: z.number().int().optional().nullable(),
  dueDate: z.string().optional().nullable()
});

export const updateInvoiceSchema = z.object({
  status: z.enum(['مدفوعة', 'معلقة', 'متأخرة', 'ملغية']).optional(),
  paidAt: z.string().optional()
});

export const createVendorSchema = z.object({
  name: z.string().min(1, 'اسم المورد مطلوب').max(100),
  category: z.string().min(1, 'الفئة مطلوبة'),
  phone: z.string().optional().default(''),
  email: z.string().email().optional().or(z.literal('')).default(''),
  city: z.string().optional().default(''),
  notes: z.string().max(1000).optional().default('')
});
