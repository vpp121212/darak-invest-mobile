export const errorHandler = (err, req, res, next) => {
  console.error('Error:', err.message);

  if (err.name === 'ValidationError') {
    const messages = Object.values(err.errors).map(e => e.message);
    return res.status(400).json({ error: 'خطأ في البيانات', details: messages });
  }
  if (err.code === 11000) {
    return res.status(400).json({ error: 'البيانات موجودة مسبقاً' });
  }
  if (err.name === 'CastError') {
    return res.status(400).json({ error: 'معرف غير صالح' });
  }
  if (err.name === 'JsonWebTokenError') {
    return res.status(401).json({ error: 'رمز غير صالح' });
  }
  if (err.name === 'TokenExpiredError') {
    return res.status(401).json({ error: 'انتهت صلاحية الرمز' });
  }

  res.status(err.statusCode || 500).json({
    error: err.message || 'خطأ داخلي في السيرفر'
  });
};
