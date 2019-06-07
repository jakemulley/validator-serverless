const handler = require('./handler');
const fs = require('fs');

const event = {};

handler.handler(event, {}, function(data, ss) { console.log(data, ss) })

event.data = []

handler.handler(event, {}, function(data, ss) { console.log(data, ss) })

event.schema = 'schema'

handler.handler(event, {}, function(data, ss) { console.log(data, ss) })

event.data = fs.readFileSync(process.cwd() + '/malformed.csv');

handler.handler(event, {}, function(data, ss) { console.log(data, ss) })

event.data = fs.readFileSync(process.cwd() + '/invalid.csv');

handler.handler(event, {}, function(data, ss) { console.log(data, ss) })

event.data = fs.readFileSync(process.cwd() + '/valid.csv');

handler.handler(event, {}, function(data, ss) { console.log(data, ss) })
