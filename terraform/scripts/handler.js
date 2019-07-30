const axios = require('axios')
const AWS = require('aws-sdk')
const csv = require('csvtojson')
const Ajv = require('ajv')

const baseParams = {
  TableName: 'ValidatorBrownfieldSites'
}

const s3Params = {
  Bucket: 'validatorbrownfieldsites'
}

// AWS Setup
AWS.config.update({ region: 'eu-west-2' })
const ddb = new AWS.DynamoDB.DocumentClient({ apiVersion: '2012-08-10' })
const s3 = new AWS.S3({ apiVersion: '2006-03-01', params: s3Params })

// AJV Setup
const ajv = new Ajv({
  allErrors: true,
  coerceTypes: true
})

const d = new Date()

const actions = {
  async retrieve (url, type) {
    return axios.get(url, { timeout: 5000, responseType: type })
  },
  async transformCsv (data) {
    return csv().fromString(data)
  },
  async store (jsonRepresenation) {
    const promises = []
    const params = {
      RequestItems: {}
    }

    while (jsonRepresenation.length) {
      const chunk = params
      chunk.RequestItems[baseParams.TableName] = jsonRepresenation.splice(0, 25).map(item => ({
        PutRequest: {
          Item: {
            organisation: item.organisation.toString() || null,
            date: d.toISOString().split('T')[0],
            'register-url': item['register-url'].toString() || null,
            validated: {
              isValid: null,
              isCsv: null,
              hasRequiredHeaders: null,
              statusCode: null
            }
          }
        }
      }))

      promises.push(ddb.batchWrite(chunk).promise())
    }

    return Promise.all(promises)
  },
  async upload (key, stream) {
    const params = Object.assign({ Key: key, Body: stream }, s3Params)
    return s3.upload(params).promise()
  },
  async getFile (key) {
    const params = Object.assign({ Key: key }, s3Params)
    return s3.getObject(params).promise()
  },
  formatResponseForLambda (data) {
    return {
      isBase64Encoded: false,
      statusCode: 200,
      headers: { 'Content-Type': 'application/json' },
      body: (data) ? JSON.stringify(data) : JSON.stringify({})
    }
  }
}

exports.getMaster = async type => {
  try {
    const res = await actions.retrieve('https://raw.githubusercontent.com/digital-land/alpha-data/master/mhclg-registers/brownfield-register-index.csv', 'text')
    const json = await actions.transformCsv(res.data)
    console.log('getMaster => Storing data =>', JSON.stringify(json, null, 4))
    return await actions.store(json)
  } catch (error) {
    console.log(error)
  }
}

exports.fetchTodaysResults = async request => {
  if (request.queryStringParameters && request.queryStringParameters.organisation) {
    return exports.fetchOrganisationResults(request)
  }
  if (request.queryStringParameters && request.queryStringParameters.url) {
    return exports.checkUrl(request)
  }
  if (request.queryStringParameters && request.queryStringParameters.file) {
    return exports.validateFile(request.queryStringParameters.file)
  }
  const params = Object.assign({}, baseParams)
  params.KeyConditionExpression = '#d = :d'
  params.ExpressionAttributeNames = {
    '#d': 'date'
  }
  params.ExpressionAttributeValues = {
    ':d': new Date().toISOString().split('T')[0]
  }
  params.ScanIndexForward = false
  try {
    const res = await ddb.query(params).promise()
    console.log('fetchTodaysResults called =>', JSON.stringify(res, null, 4))
    return actions.formatResponseForLambda(res.Items)
  } catch (error) {
    console.error('Error fetchTodaysResults =>', error)
    return { error, message: 'Error on fetchTodaysResults' }
  }
}

exports.fetchOrganisationResults = async request => {
  const params = Object.assign({}, baseParams)
  params.IndexName = 'OrganisationDateIndex'
  params.KeyConditionExpression = '#o = :o'
  params.ExpressionAttributeNames = {
    '#o': 'organisation'
  }
  params.ExpressionAttributeValues = {
    ':o': request.queryStringParameters.organisation
  }
  params.ScanIndexForward = false
  try {
    const res = await ddb.query(params).promise()
    return actions.formatResponseForLambda(res.Items)
  } catch (error) {
    console.error('Error fetchOrganisationResults =>', error)
    return { error, message: 'Error on fetchOrganisationResults' }
  }
}

exports.retrieveFile = async stream => {
  const found = stream.Records.find(item => item.eventName === 'INSERT')
  if (found && found.dynamodb.NewImage['register-url']) {
    try {
      const res = await actions.retrieve(found.dynamodb.NewImage['register-url'].S, 'stream')
      res.headers.status = {
        code: res.status,
        text: res.statusText
      }

      const key = `brownfield-sites/${found.dynamodb.NewImage['organisation'].S}/${d.toISOString().split('T')[0]}`

      await actions.upload(`${key}/headers.json`, JSON.stringify(res.headers)).then(r => {
        console.log('retrieveFile NO ERROR (headers) =>', r)
      }).catch(error => {
        console.log('retrieveFile ERROR (headers) =>', error)
      })
      await actions.upload(`${key}/response`, res.data).then(r => {
        console.log('retrieveFile NO ERROR (response) =>', r)
      }).catch(error => {
        console.log('retrieveFile ERROR (response) =>', error)
      })

      // update item here with status / s3 reference
    } catch (error) {
      console.error('Error retrieveFile =>', error)
    }
  }
}

exports.validateFile = async stream => {
  const returnable = {
    isValid: null,
    isCsv: null,
    hasRequiredHeaders: null,
    statusCode: null
  }
  const found = stream.Records.find(item => item.eventName === 'ObjectCreated:Put' && !item.s3.object.key.endsWith('validated.json'))
  const decoded = decodeURIComponent(found.s3.object.key)

  if (found) {
    try {
      const file = await actions.getFile(decoded) // change to found.s3.object.key
      const notBuffer = file.Body.toString('utf-8')
      const updateParams = Object.assign({}, baseParams)
      const splitStream = decoded.split('/')
      updateParams.Key = {
        date: splitStream[2],
        organisation: splitStream[1]
      }

      if (decoded.endsWith('headers.json')) {
        const json = JSON.parse(notBuffer)

        updateParams.UpdateExpression = 'set validated.statusCode = :sc'
        updateParams.ExpressionAttributeValues = {
          ':sc': json.status.code
        }
      } else {
        try {
          if (!notBuffer.toLowerCase().includes('doctype') && notBuffer.toLowerCase().includes(',')) {
            const json = await actions.transformCsv(notBuffer)
            returnable.isCsv = true

            const compiledValidator = ajv.compile(require('./brownfield-schema.json'))
            const parsedByRow = json.map(row => {
              const validatedRow = compiledValidator(row)

              row.validator = {
                isRowValid: validatedRow,
                rowErrors: compiledValidator.errors || []
              }

              return row
            })

            if (parsedByRow.length) {
              returnable.isValid = parsedByRow.every(row => row.isRowValid === true)
              returnable.hasRequiredHeaders = parsedByRow.every(row => row.validator.rowErrors.every(r => r.keyword !== 'required'))
            }

            // try {
            //   // await actions.upload(stream.)
            // } catch(error) {
            //   console.log('Error uploading S3 file => validateFile', error)
            // }
          } else {
            returnable.isCsv = false
          }
        } catch (error) {
          returnable.isCsv = false
        }

        updateParams.UpdateExpression = 'set validated.isCsv = :csv, validated.hasRequiredHeaders = :headers, validated.isValid = :v'
        updateParams.ExpressionAttributeValues = {
          ':csv': returnable.isCsv,
          ':headers': returnable.hasRequiredHeaders,
          ':v': returnable.isValid
        }
      }

      console.log(JSON.stringify(updateParams, null, 4))

      return await ddb.update(updateParams).promise()
    } catch (error) {
      console.log('Error validateFile =>', error)
    }
  }
}

exports.checkUrl = async request => {
  const returnable = {
    isValid: null,
    isCsv: null,
    hasRequiredHeaders: null,
    statusCode: null
  }

  try {
    const urlResponse = await actions.retrieve(request.queryStringParameters.url)
    returnable.statusCode = urlResponse.status

    try {
      const json = await actions.transformCsv(urlResponse.data)
      if (!urlResponse.data.toLowerCase().includes('doctype') && !urlResponse.headers['content-type'].includes('pdf')) {
        returnable.isCsv = true

        const compiledValidator = ajv.compile(require('./brownfield-schema.json'))
        const parsedByRow = json.map(row => {
          const validatedRow = compiledValidator(row)

          row.validator = {
            isRowValid: validatedRow,
            rowErrors: compiledValidator.errors || []
          }

          return row
        })

        if (parsedByRow.length) {
          returnable.isValid = parsedByRow.every(row => row.isRowValid === true)
          returnable.hasRequiredHeaders = parsedByRow.every(row => row.validator.rowErrors.every(r => r.keyword !== 'required'))
        }
      } else {
        returnable.isCsv = false
      }
    } catch (error) {
      returnable.isCsv = false
    }
  } catch (error) {
    if (error.response) {
      returnable.statusCode = error.response.status
    } else {
      returnable.statusCode = 500
    }

    console.log('Error => checkUrl =>', error)
  }

  return actions.formatResponseForLambda(returnable)
}
