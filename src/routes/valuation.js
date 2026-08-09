import { Router } from 'express';
import aiRoutes from './ai.js';
import valuationReportRoutes from './valuationReports.js';

const router = Router();

// تجميع مجموعة Valuation API: /estimate + /match + سجل التقارير المحفوظة.
router.use(aiRoutes);
router.use(valuationReportRoutes);

export default router;
