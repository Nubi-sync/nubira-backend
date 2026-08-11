import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, ManyToOne, JoinColumn } from 'typeorm';
import { User } from '../../users/entities/user.entity';

@Entity('audit_logs')
export class AuditLog {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  action: string; // e.g., 'PO_CREATED', 'BUNDLE_SCANNED'

  @Column({ nullable: true })
  entityName: string; // e.g., 'ProductionOrder', 'Bundle'

  @Column({ nullable: true })
  entityId: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'performed_by' })
  performedBy: User;

  @Column({ type: 'jsonb', nullable: true })
  details: any;

  @CreateDateColumn()
  timestamp: Date;
}
