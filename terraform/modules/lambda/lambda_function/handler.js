const AJV = require('ajv');
const AWS = require('aws-sdk');
const csv = require('csvtojson');
const ajv = new AJV({
  allErrors: true,
  verbose: true,
  coerceTypes: true,
  useDefaults: 'empty'
});

const actions = {
  async validate(schema, data) {
    const json = await csv().fromString(data.toString());
    const validator = ajv.compile(require(`./${schema}.json`));
    const validated = json.filter(item => Object.values(item).some(result => result.length)).map(item => {
      let valid = validator(item);
      item.valid = valid;
      item.errors = valid ? [] : validator.errors;
      return item
    });

    return {
      data_hash: data.toString().length,
      result: validated,
      valid: validated.map(row => row.valid).every(item => item !== false)
    };
  },
  store() {

  }
}

exports.handler = async (event, context, callback) => {
  let error = {};
  let response = {
    "isBase64Encoded": false,
    "statusCode": 200,
    "headers": { "Content-Type": "application/json" },
    "body": ""
  };

  event.body = JSON.parse(event.body);

  if(!event.body.schema) {
    error.message = ['Failed operation: no schema specified']
  }

  if(!event.body.data) {
    error.message = ['Failed operation: no data specified']
  }

  if(Object.keys(error).includes('message')) {
    response.body = JSON.stringify(error);
    callback(response,  null);
  } else {
    const output = await actions.validate(event.body.schema, event.body.data);
    response.body = JSON.stringify(output);
    callback(null, response);
  }
}
