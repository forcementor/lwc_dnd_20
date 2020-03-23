const express=require('express')
const app=express()
app.use(express.static('.'))
app.listen(3000, () => console.log('Slide show running on posrt 3000!'))