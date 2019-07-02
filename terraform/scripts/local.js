const handler = require('./handler.js')

// handler.getMaster({}, {}, function (a, b) {
//   console.log(a, b)
// })

// async function test () {
//   const res = await handler.getOrgResults({})
//   // console.log(res)

//   const parsed = JSON.parse(res.body)

//   return Promise.all(parsed.Items.map(async function (item) {
//     return handler.validate(item, {}, function (a, b) {
//       console.log(a, b)
//     })
//   }))
// }

// test()

// // handler.validate({
// //   'hash': {
// //     S: '66a84c880fde43ddf40faad3f5c8ca6472927c15'

// //   },
// //   'register-url': {
// //     S: 'http://www.boston.gov.uk/CHttpHandler.ashx?id=22192&p=0'
// //   }
// // }, {}, function (a, b) {
// //   console.log(a, b)
// // })

handler.validate(
  {
    'Records': [
      {
        'eventID': '6b237181422014e789f9b944aab50172',
        'eventName': 'INSERT',
        'eventVersion': '1.1',
        'eventSource': 'aws:dynamodb',
        'awsRegion': 'eu-west-2',
        'dynamodb': {
          'ApproximateCreationDateTime': 1561373354,
          'Keys': {
            'hash': {
              'S': 'a9fb8c1073ee8f8f1f20c99287d673c0b9a3e8a5'
            }
          },
          'NewImage': {
            'date': {
              'S': '2019-06-24'
            },
            'register-url': {
              'S': 'http://www.bromley.gov.uk/download/downloads/id/3318/brownfield_land_register.csv'
            },
            'validated': {
              'NULL': true
            },
            'organisation': {
              'S': 'local-authority-eng:CHN'
            },
            'hash': {
              'S': 'a9fb8c1073ee8f8f1f20c99287d673c0b9a3e8a5'
            }
          },
          'SequenceNumber': '19891100000000001150423999',
          'SizeBytes': 279,
          'StreamViewType': 'NEW_IMAGE'
        },
        'eventSourceARN': 'arn:aws:dynamodb:eu-west-2:391391913775:table/ValidatorBrownfield/stream/2019-06-24T10:10:29.806'
      },
      {
        'eventID': 'e7e4ebacd21a84683d033c2437ae7638',
        'eventName': 'MODIFY',
        'eventVersion': '1.1',
        'eventSource': 'aws:dynamodb',
        'awsRegion': 'eu-west-2',
        'dynamodb': {
          'ApproximateCreationDateTime': 1561373354,
          'Keys': {
            'hash': {
              'S': 'a5ffedc0a95c8bc911cfe79adf15d31d6e544715'
            }
          },
          'NewImage': {
            'date': {
              'S': '2019-06-24'
            },
            'register-url': {
              'S': 'http://www.babergh.gov.uk/assets/Planning-Policy/BMSDC-BrownfieldRegister-2017-12-21.csv'
            },
            'validated': {
              'NULL': true
            },
            'organisation': {
              'S': 'local-authority-eng:CHR'
            },
            'hash': {
              'S': 'a5ffedc0a95c8bc911cfe79adf15d31d6e544715'
            }
          },
          'SequenceNumber': '19891200000000001150424000',
          'SizeBytes': 256,
          'StreamViewType': 'NEW_IMAGE'
        },
        'eventSourceARN': 'arn:aws:dynamodb:eu-west-2:391391913775:table/ValidatorBrownfield/stream/2019-06-24T10:10:29.806'
      }
    ]
  }
)

// handler.getOrgResults({
//   queryStringParameters: {
//     organisation: 'local-authority-eng:KWL'
//   }
// })

// handler.getOrgResults({})
