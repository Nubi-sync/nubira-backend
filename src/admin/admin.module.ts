import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AdminController } from './admin.controller';
import { AdminService } from './admin.service';
import { ArticlesModule } from './articles/articles.module';
import { LinesModule } from './lines/lines.module';
import { ProductionOrder } from './entities/production-order.entity';
import { Bundle } from '../lineman/entities/bundle.entity';
import { AuditModule } from '../audit/audit.module';
import { UsersModule } from '../users/users.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([ProductionOrder, Bundle]),
    ArticlesModule, 
    LinesModule,
    UsersModule,
    AuditModule
  ],
  controllers: [AdminController],
  providers: [AdminService],
})
export class AdminModule {}
