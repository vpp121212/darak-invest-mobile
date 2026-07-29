export class AppError extends Error {
  constructor({ code, message, status = 400, details }) {
    super(message);
    this.code = code;
    this.status = status;
    this.details = details;
    this.name = 'AppError';
  }

  toJSON() {
    const body = { code: this.code, message: this.message };
    if (this.details) body.details = this.details;
    return body;
  }
}

export const Errors = {
  validation(details) {
    return new AppError({ code: 'VALIDATION_ERROR', message: 'بيانات غير صالحة', details });
  },
  notFound(resource = 'المورد') {
    return new AppError({ code: 'NOT_FOUND', message: `${resource} غير موجود`, status: 404 });
  },
  duplicate(field = 'البيانات') {
    return new AppError({ code: 'DUPLICATE', message: `${field} مسجل مسبقاً` });
  },
  unauthorized(msg = 'غير مصرح') {
    return new AppError({ code: 'UNAUTHORIZED', message: msg, status: 401 });
  },
  forbidden(msg = 'لا تملك صلاحية') {
    return new AppError({ code: 'FORBIDDEN', message: msg, status: 403 });
  },
  invalidToken(msg = 'رمز غير صالح') {
    return new AppError({ code: 'INVALID_TOKEN', message: msg, status: 401 });
  },
  expiredToken() {
    return new AppError({ code: 'EXPIRED_TOKEN', message: 'انتهت صلاحية الرمز', status: 401 });
  },
  internal(msg = 'خطأ داخلي في السيرفر') {
    return new AppError({ code: 'INTERNAL_ERROR', message: msg, status: 500 });
  },
  custom(code, message, status = 400, details) {
    return new AppError({ code, message, status, details });
  }
};
