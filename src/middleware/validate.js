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
  return schema.safeParse
    ? schema.safeParse(data)
    : { success: true, data: schema.validate(data, { abortEarly: false, stripUnknown: true }) };
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
      req.query = result.data;
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
