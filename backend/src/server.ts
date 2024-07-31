import express, { Express, Request, Response } from 'express'
import {router} from "./controllers/router.controller";
const server: Express = express()
const port: number = 3000

server.get('/', (req: Request, res: Response): void => {
	res.send('Server is working')
})
server.use('/router', router)

server.listen(port, (): void => {
	console.log('Server started on port ' + port)
})