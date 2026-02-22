const express = require('express')
const app = express()

app.get('/', (req, res) => {
  res.send('Hello from ArgoCD 🚀')
})

app.listen(3000, () => console.log('Running on 3000'))