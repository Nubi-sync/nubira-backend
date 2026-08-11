import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource } from 'typeorm';
import { Bundle, BundleStatus } from '../lineman/entities/bundle.entity';
import { WageLedger } from '../lineman/entities/wage-ledger.entity';
import { AuditService } from '../audit/audit.service';

@Injectable()
export class ScannerService {
  constructor(
    @InjectRepository(Bundle)
    private readonly bundleRepository: Repository<Bundle>,
    private readonly dataSource: DataSource,
    private readonly auditService: AuditService,
  ) {}

  async processSyncPayload(user: any, payloads: any[]) {
    const results = {
      success: 0,
      failed: 0,
      errors: [] as string[],
    };

    for (const payload of payloads) {
      try {
        await this.processSingleScan(user, payload);
        results.success++;
      } catch (err: any) {
        results.failed++;
        results.errors.push(`Barcode ${payload.barcode}: ${err.message}`);
      }
    }

    return results;
  }

  private async processSingleScan(user: any, payload: any) {
    const { barcode, context, timestamp } = payload;
    // context can be: RECEIVE, ISSUE, QC_PASS, STORE_INWARD, STORE_OUTWARD
    
    // We must run in a transaction because we might insert WageLedger and update Bundle
    await this.dataSource.transaction(async manager => {
      const bundle = await manager.findOne(Bundle, {
        where: { barcode },
        relations: {
          productionOrder: {
            assignedLineman: true
          }
        },
      });

      if (!bundle) {
        throw new NotFoundException('Bundle not found');
      }

      // 1. LINEMAN: RECEIVE (IN_STORE -> WITH_LINEMAN)
      if (context === 'RECEIVE') {
        if (user.role !== 'LINEMAN') throw new BadRequestException('Unauthorized role');
        if (bundle.status !== BundleStatus.IN_STORE) {
          throw new BadRequestException('Bundle is not IN_STORE');
        }
        if (bundle.productionOrder.assignedLineman?.id !== user.id) {
          throw new BadRequestException('Bundle not assigned to you');
        }
        
        bundle.status = BundleStatus.WITH_LINEMAN;
        await manager.save(bundle);
      }
      
      // 2. LINEMAN: ISSUE (WITH_LINEMAN -> PENDING_QC) and CALC WAGE
      else if (context === 'ISSUE') {
        if (user.role !== 'LINEMAN') throw new BadRequestException('Unauthorized role');
        if (bundle.status !== BundleStatus.WITH_LINEMAN) {
          throw new BadRequestException('Bundle must be received first');
        }
        
        bundle.status = BundleStatus.PENDING_QC;
        await manager.save(bundle);

        // Auto-credit wage
        const wageAmount = bundle.quantity * bundle.productionOrder.piece_rate;
        const wage = manager.create(WageLedger, {
          lineman: user,
          bundle: bundle,
          amount: wageAmount
        });
        await manager.save(wage);
      }
      
      // 3. QC: PASS (PENDING_QC -> COMPLETED_QC)
      else if (context === 'QC_PASS') {
        if (user.role !== 'PRODUCTION' && user.role !== 'ADMIN') throw new BadRequestException('Unauthorized role');
        if (bundle.status !== BundleStatus.PENDING_QC) {
          throw new BadRequestException('Bundle is not pending QC');
        }
        bundle.status = BundleStatus.COMPLETED_QC;
        bundle.passed_quantity = payload.passedQuantity ?? bundle.quantity;
        bundle.rejected_quantity = payload.rejectedQuantity ?? 0;
        await manager.save(bundle);
      }

      // 4. STORE: OUTWARD (COMPLETED_QC -> DISPATCHED)
      else if (context === 'STORE_OUTWARD') {
        if (user.role !== 'STORE' && user.role !== 'ADMIN') throw new BadRequestException('Unauthorized role');
        if (bundle.status !== BundleStatus.COMPLETED_QC) {
          throw new BadRequestException('Bundle is not completed QC');
        }
        bundle.status = BundleStatus.DISPATCHED;
        await manager.save(bundle);
      }

      else {
        throw new BadRequestException('Invalid context');
      }

      await this.auditService.logAction(
        `BUNDLE_SCANNED_${context}`,
        user,
        'Bundle',
        bundle.id,
        { barcode, context }
      );
    });
  }
}
