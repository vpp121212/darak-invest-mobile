import Joi from 'joi';
import { z } from 'zod';

export const propertyQuerySchema = z.object({
  city: z.string().optional(),
  type: z.string().optional(),
  purpose: z.enum(['بيع', 'إيجار']).optional(),
  minPrice: z.coerce.number().positive().optional(),
  maxPrice: z.coerce.number().positive().optional(),
  minArea: z.coerce.number().positive().optional(),
  maxArea: z.coerce.number().positive().optional(),
  rooms: z.coerce.number().int().min(0).optional(),
  sort: z.string().optional(),
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20)
});

const imageSchema = Joi.string();
const featureSchema = Joi.string();

export const createPropertySchema = Joi.object({
  title: Joi.string().min(3).max(200).required().messages({
    'string.min': 'العنوان يجب أن يكون 3 أحرف على الأقل',
    'string.max': 'العنوان طويل جداً',
    'any.required': 'العنوان مطلوب'
  }),
  type: Joi.string().valid('شقة', 'فيلا', 'أرض', 'مكتب', 'محل', 'مستودع', 'استراحة', 'مجمع', 'عمارة', 'دور', 'شاليه').required().messages({
    'any.only': 'نوع العقار غير صالح',
    'any.required': 'نوع العقار مطلوب'
  }),
  purpose: Joi.string().valid('بيع', 'إيجار').required().messages({
    'any.only': 'الغرض يجب أن يكون بيع أو إيجار',
    'any.required': 'الغرض مطلوب'
  }),
  price: Joi.number().positive().required().messages({
    'number.positive': 'السعر يجب أن يكون أكبر من صفر',
    'any.required': 'السعر مطلوب'
  }),
  area: Joi.number().positive().required().messages({
    'number.positive': 'المساحة يجب أن تكون أكبر من صفر',
    'any.required': 'المساحة مطلوبة'
  }),
  rooms: Joi.number().integer().min(0).max(50).default(0),
  baths: Joi.number().integer().min(0).max(50).default(0),
  cars: Joi.number().integer().min(0).max(20).default(0),
  facing: Joi.string().valid('شمالي', 'جنوبي', 'شرقي', 'غربي', '').optional(),
  year: Joi.number().integer().min(1950).max(new Date().getFullYear() + 1).optional(),
  age: Joi.number().integer().min(0).max(200).default(0),
  description: Joi.string().max(2000).allow('').optional(),
  city: Joi.string().required().messages({ 'any.required': 'المدينة مطلوبة' }),
  district: Joi.string().required().messages({ 'any.required': 'الحي مطلوب' }),
  area_name: Joi.string().allow('').optional(),
  street: Joi.string().allow('').optional(),
  streetWidth: Joi.number().min(0).max(200).optional(),
  lat: Joi.number().min(-90).max(90).optional(),
  lng: Joi.number().min(-180).max(180).optional(),
  features: Joi.array().items(featureSchema).default([]),
  images: Joi.array().items(imageSchema).default([]),
  panoramicImage: Joi.string().uri().allow('', null).optional(),
  trust: Joi.string().valid('direct', 'verified', 'premium', 'agency').default('direct')
}).options({ stripUnknown: true });

export const updatePropertySchema = Joi.object({
  title: Joi.string().min(3).max(200),
  type: Joi.string().valid('شقة', 'فيلا', 'أرض', 'مكتب', 'محل', 'مستودع', 'استراحة', 'مجمع', 'عمارة', 'دور', 'شاليه'),
  purpose: Joi.string().valid('بيع', 'إيجار'),
  price: Joi.number().positive(),
  area: Joi.number().positive(),
  rooms: Joi.number().integer().min(0).max(50),
  baths: Joi.number().integer().min(0).max(50),
  cars: Joi.number().integer().min(0).max(20),
  facing: Joi.string().valid('شمالي', 'جنوبي', 'شرقي', 'غربي', '').allow(''),
  year: Joi.number().integer().min(1950).max(new Date().getFullYear() + 1),
  age: Joi.number().integer().min(0).max(200),
  description: Joi.string().max(2000).allow(''),
  city: Joi.string(),
  district: Joi.string(),
  area_name: Joi.string().allow(''),
  street: Joi.string().allow(''),
  streetWidth: Joi.number().min(0).max(200),
  lat: Joi.number().min(-90).max(90),
  lng: Joi.number().min(-180).max(180),
  features: Joi.array().items(featureSchema),
  trust: Joi.string().valid('direct', 'verified', 'premium', 'agency')
}).min(1).messages({ 'object.min': 'يرجى إرسال حقل واحد على الأقل للتحديث' }).options({ stripUnknown: true });
