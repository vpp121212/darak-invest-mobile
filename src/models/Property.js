import mongoose from 'mongoose';

const propertySchema = new mongoose.Schema({
  title: { type: String, required: true },
  type: { type: String, required: true, enum: ['فيلا','شقة','بنتهاوس','قصر','دوبلكس','مكتب','شاليه','مزرعة','محل','مجمع','استراحة','غرفة','برج','بيت','ورشة','مستودع','مصنع','محطة'] },
  purpose: { type: String, required: true, enum: ['بيع', 'إيجار'] },
  price: { type: Number, required: true },
  area: { type: Number, required: true },
  rooms: { type: Number, required: true },
  baths: { type: Number, required: true },
  cars: { type: Number, default: 0 },
  facing: { type: String, default: 'شمالي' },
  year: Number,
  age: { type: Number, default: 0 },
  description: { type: String, required: true },

  city: { type: String, required: true },
  district: { type: String, required: true },
  area_name: String,
  street: String,
  streetWidth: Number,
  lat: Number,
  lng: Number,

  images: [{ type: String }],
  panoramicImage: { type: String },
  floorPlan: { type: String },

  features: [String],
  trust: { type: String, enum: ['verified', 'office', 'direct'], default: 'direct' },
  status: { type: String, enum: ['pending', 'active', 'sold', 'expired'], default: 'pending' },
  isFeatured: { type: Boolean, default: false },
  views: { type: Number, default: 0 },
  favorites: { type: Number, default: 0 },

  agent: {
    id: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    name: String,
    phone: String,
    office: String,
    officeId: { type: mongoose.Schema.Types.ObjectId, ref: 'Agent' }
  },

  aiPricing: {
    expected: Number,
    suitable: Number,
    maximum: Number,
    saleChance: Number,
    lastUpdated: Date
  }

}, { timestamps: true });

propertySchema.index({ city: 1, district: 1 });
propertySchema.index({ type: 1, purpose: 1 });
propertySchema.index({ price: 1 });
propertySchema.index({ title: 'text', description: 'text', district: 'text' });

export default mongoose.model('Property', propertySchema);
