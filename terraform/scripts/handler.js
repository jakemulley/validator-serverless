const Ajv = require('ajv')
const AWS = require('aws-sdk')
const axios = require('axios')
const crypto = require('crypto')
const csv = require('csvtojson')

// AWS Setup
AWS.config.update({ region: 'eu-west-2' })
const ddb = new AWS.DynamoDB.DocumentClient({ apiVersion: '2012-08-10' })

// Validator Setup
const ajv = new Ajv({
  allErrors: true,
  coerceTypes: true,
  jsonPointers: true
})

// DynamoDB options
const baseParams = {
  TableName: 'ValidatorServerless'
}

// Reusable methods
const actions = {
  async retrieve (url) {
    return axios.get(url, { timeout: 10000 })
  },
  async csvToJson (data) {
    return csv().fromString(data)
  },
  async storeMaster (transformed) {
    const promises = []
    const params = {
      RequestItems: {}
    }

    while (transformed.length) {
      const chunk = params
      chunk.RequestItems[baseParams.TableName] = transformed.splice(0, 25).map(item => ({
        'PutRequest': {
          'Item': {
            'date': new Date().toISOString().split('T')[0],
            'hash': crypto.randomBytes(20).toString('hex'),
            'organisation': item.organisation.toString() || null,
            'register-url': item['register-url'].toString() || null,
            'validated': null,
            'validatedErrors': null
          }
        }
      }))
      promises.push(ddb.batchWrite(params).promise())
    }

    return Promise.all(promises)
  },
  async validate (streamItem) {
    return Promise.all(streamItem.splice(0, 1).map(async item => {
      const compiledValidator = ajv.compile(require('./brownfield-schema.json'))
      const validatorObject = {
        isValid: false,
        isCsv: false,
        hasRequiredHeaders: false,
        statusCode: false
      }

      const formattedStreamItem = {}
      for (let [key, value] of Object.entries(item.dynamodb.NewImage)) {
        formattedStreamItem[key] = value.S || null
      }

      if (formattedStreamItem['register-url']) {
        console.log('Validating:', formattedStreamItem['register-url'])

        try {
          const register = await actions.retrieve(formattedStreamItem['register-url'])
          validatorObject.statusCode = register.status

          if (!register.data.toLowerCase().includes('doctype') && !register.headers['content-type'].includes('pdf')) {
            const transformed = await actions.csvToJson(register.data)
            validatorObject.isCsv = true

            let parsedByRow = transformed.map(function (row) {
              const validatedRow = compiledValidator(row)

              row.validator = {
                isRowValid: validatedRow,
                rowErrors: compiledValidator.errors || []
              }

              return row
            }) || []

            if (parsedByRow.length) {
              validatorObject.isValid = parsedByRow.every(row => row.validator.isRowValid === true)
              validatorObject.hasRequiredHeaders = parsedByRow.every(row => row.validator.rowErrors.every(r => r.keyword !== 'required'))
              formattedStreamItem.validatedErrors = JSON.stringify(parsedByRow) || null
            }
          }
        } catch (error) {
          if (error.response) {
            validatorObject.statusCode = error.response.status
          } else {
            validatorObject.statusCode = 500
          }
          console.log('Error', error)
        }
      }

      formattedStreamItem.validated = JSON.stringify(validatorObject)

      console.log(formattedStreamItem)

      return formattedStreamItem
    }))
  }
}

// Handlers
exports.getMaster = async () => {
  try {
    const master = await actions.retrieve('https://raw.githubusercontent.com/digital-land/alpha-data/master/mhclg-registers/brownfield-register-index.csv')
    const data = await actions.csvToJson(master.data)
    return await actions.storeMaster(data)
  } catch (error) {
    console.log('Error => getMaster =>', error)
    return error
  }
}

exports.validate = async (stream) => {
  const should = stream.Records.some(item => item.eventName === 'INSERT')

  if (should) {
    try {
      console.log('Stream:', JSON.stringify(stream, null, 4))
      const validated = await actions.validate(stream.Records)
      const params = Object.assign({ Item: validated[0] }, baseParams)
      return await ddb.put(params).promise()
    } catch (error) {
      console.log('Error => validate =>', error)
      return error
    }
  }
}

exports.getOrgResults = async (request) => {
  const params = Object.assign({
    ExpressionAttributeNames: {
      '#f': ''
    },
    ExpressionAttributeValues: {
      ':f': {}
    },
    FilterExpression: '#f = :f'
  }, baseParams)
  let body = {}

  if (request.queryStringParameters && request.queryStringParameters.organisation) {
    params.ExpressionAttributeNames['#f'] = 'organisation'
    params.ExpressionAttributeValues[':f'] = request.queryStringParameters.organisation
  } else {
    params.ExpressionAttributeNames['#f'] = 'date'
    params.ExpressionAttributeValues[':f'] = new Date().toISOString().split('T')[0]
  }

  let item = await ddb.scan(params).promise()

  body = item

  body.Items = item.Items.map(it => {
    it.validated = JSON.parse(it.validated) || null
    delete it.validatedErrors
    return it
  })

  if (request.queryStringParameters && request.queryStringParameters.organisation) {
    body = {
      organisation: request.queryStringParameters.organisation,
      results: item.Items.map(function (result) {
        const obj = {
          'register-url': result['register-url'],
          'date': result['date'],
          'validated': result['validated']
        }
        if (result['date'] === new Date().toISOString().split('T')[0]) {
          obj.errors = result['validationErrors']
        }
        return obj
      })
    }
  }

  body.last_updated = new Date().toISOString().split('T')[0]

  return {
    isBase64Encoded: false,
    statusCode: 200,
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body)
  }
}
