import mongoose from 'mongoose';

const agentSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  officeName: { type: String, required: true },
  commercialReg: { type: String, required: true },
  city: { type: String, required: true },
  district: String,
  address: String,
  description: String,
  logo: String,
  isVerified: { type: Boolean, default: false },
  rating: { type: Number, default: 0 },
  totalSales: { type: Number, default: 0 },
  totalListings: { type: Number, default: 0 },
  phone: String,
  email: String,
  whatsapp: String
}, { timestamps: true });

export default mongoose.model('Agent', agentSchema);
