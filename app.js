const express = require('express')
const app = express()

app.get('/', (req, res) => {
  res.send('Hello Sardar you updated the app 2222 222 333')
})

app.listen(3000, () => console.log('Running on 3000'))