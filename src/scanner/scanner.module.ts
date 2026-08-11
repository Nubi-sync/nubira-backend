import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ScannerService } from './scanner.service';
import { ScannerController } from './scanner.controller';
import { Bundle } from '../lineman/entities/bundle.entity';
import { WageLedger } from '../lineman/entities/wage-ledger.entity';
import { ProductionOrder } from '../admin/entities/production-order.entity';
import { AuditModule } from '../audit/audit.module';

@Module({
  imports: [TypeOrmModule.forFeature([Bundle, WageLedger, ProductionOrder]), AuditModule],
  controllers: [ScannerController],
  providers: [ScannerService],
})
export class ScannerModule {}
