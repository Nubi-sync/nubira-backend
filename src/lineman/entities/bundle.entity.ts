import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, ManyToOne, JoinColumn } from 'typeorm';
import { ProductionOrder } from '../../admin/entities/production-order.entity';

export enum BundleStatus {
  IN_STORE = 'IN_STORE',
  WITH_LINEMAN = 'WITH_LINEMAN',
  IN_PROGRESS = 'IN_PROGRESS',
  PENDING_QC = 'PENDING_QC',
  COMPLETED_QC = 'COMPLETED_QC',
  DISPATCHED = 'DISPATCHED',
}

@Entity('bundles')
export class Bundle {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  bundle_no: string;

  @Column({ unique: true })
  barcode: string;

  @Column({ type: 'int' })
  quantity: number;

  @Column({ type: 'int', default: 0 })
  passed_quantity: number;

  @Column({ type: 'int', default: 0 })
  rejected_quantity: number;

  @Column({
    type: 'enum',
    enum: BundleStatus,
    default: BundleStatus.IN_STORE,
  })
  status: BundleStatus;

  @ManyToOne(() => ProductionOrder, (po) => po.bundles)
  @JoinColumn({ name: 'production_order_id' })
  productionOrder: ProductionOrder;

  @CreateDateColumn()
  created_at: Date;

  @UpdateDateColumn()
  updated_at: Date;
}
