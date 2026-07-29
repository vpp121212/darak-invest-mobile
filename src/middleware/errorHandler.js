export const errorHandler = (err, req, res, next) => {
  if (err.name === 'AppError') {
    return res.status(err.status).json(err.toJSON());
  }

  if (err.name === 'JsonWebTokenError') {
    return res.status(401).json({ code: 'INVALID_TOKEN', message: 'رمز غير صالح' });
  }
  if (err.name === 'TokenExpiredError') {
    return res.status(401).json({ code: 'EXPIRED_TOKEN', message: 'انتهت صلاحية الرمز' });
  }

  console.error('Unhandled:', err);
  res.status(500).json({
    code: 'INTERNAL_ERROR',
    message: 'خطأ داخلي في السيرفر'
  });
};
