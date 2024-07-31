import express, { Request, Response, Router } from 'express'
export const router: Router = Router()

router.use(express.json())
router.use(express.urlencoded({ extended: true }))
router.post('/', (req: Request, res: Response): void => {
	console.log(req.body)
	res.sendStatus(200)
})
