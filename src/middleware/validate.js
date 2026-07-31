import { Errors } from '../utils/errors.js';

function parseErrors(result) {
  if (result.error?.issues) {
    return result.error.issues.map(e => ({ field: e.path.join('.'), message: e.message }));
  }
  if (result.error?.details) {
    return result.error.details.map(e => ({ field: e.path.join('.'), message: e.message }));
  }
  return [{ message: 'بيانات غير صالحة' }];
}

function validateSchema(schema, data) {
  if (schema.safeParse) {
    return schema.safeParse(data);
  }
  const result = schema.validate(data, { abortEarly: false, stripUnknown: true });
  return { success: !result.error, data: result.value, error: result.error };
}

export const validate = {
  body(schema) {
    return (req, res, next) => {
      const result = validateSchema(schema, req.body);
      if (!result.success) {
        return res.status(400).json(Errors.validation(parseErrors(result)).toJSON());
      }
      req.body = result.data;
      next();
    };
  },
  query(schema) {
    return (req, res, next) => {
      const result = validateSchema(schema, req.query);
      if (!result.success) {
        return res.status(400).json(Errors.validation(parseErrors(result)).toJSON());
      }
      Object.defineProperty(req, 'query', { value: result.data, configurable: true, writable: true, enumerable: true });
      next();
    };
  },
  params(schema) {
    return (req, res, next) => {
      const result = validateSchema(schema, req.params);
      if (!result.success) {
        return res.status(400).json(Errors.validation(parseErrors(result)).toJSON());
      }
      req.params = result.data;
      next();
    };
  }
};
