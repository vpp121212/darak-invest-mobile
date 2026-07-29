export const validate = {
  body(schema) {
    return (req, res, next) => {
      const result = schema.safeParse
        ? schema.safeParse(req.body)
        : { success: true, data: schema.validate(req.body, { abortEarly: false, stripUnknown: true }) };
      if (!result.success) {
        const errors = result.error?.issues
          ? result.error.issues.map(e => ({ field: e.path.join('.'), message: e.message }))
          : result.error?.details
            ? result.error.details.map(e => ({ field: e.path.join('.'), message: e.message }))
            : [{ message: 'بيانات غير صالحة' }];
        return res.status(400).json({ error: 'بيانات غير صالحة', details: errors });
      }
      req.body = result.data;
      next();
    };
  },
  query(schema) {
    return (req, res, next) => {
      const result = schema.safeParse
        ? schema.safeParse(req.query)
        : schema.validate(req.query, { abortEarly: false, stripUnknown: true });
      if (!result.success) {
        const errors = result.error?.issues
          ? result.error.issues.map(e => ({ field: e.path.join('.'), message: e.message }))
          : result.error?.details
            ? result.error.details.map(e => ({ field: e.path.join('.'), message: e.message }))
            : [{ message: 'معاملات غير صالحة' }];
        return res.status(400).json({ error: 'معاملات غير صالحة', details: errors });
      }
      req.query = result.data;
      next();
    };
  },
  params(schema) {
    return (req, res, next) => {
      const result = schema.safeParse
        ? schema.safeParse(req.params)
        : schema.validate(req.params, { abortEarly: false, stripUnknown: true });
      if (!result.success) {
        return res.status(400).json({ error: 'معاملات غير صالحة' });
      }
      req.params = result.data;
      next();
    };
  }
};
