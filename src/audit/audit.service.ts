import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { AuditLog } from './entities/audit.entity';

@Injectable()
export class AuditService {
  constructor(
    @InjectRepository(AuditLog)
    private readonly auditRepository: Repository<AuditLog>,
  ) {}

  async logAction(action: string, performedBy: any, entityName?: string, entityId?: string, details?: any, manager?: any) {
    const log = this.auditRepository.create({
      action,
      performedBy,
      entityName,
      entityId,
      details,
    });
    if (manager) {
      return manager.save(log);
    }
    return this.auditRepository.save(log);
  }

  async getRecentLogs(limit: number = 50) {
    return this.auditRepository.find({
      relations: { performedBy: true },
      order: { timestamp: 'DESC' },
      take: limit,
    });
  }
}
