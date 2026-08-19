import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, ManyToOne, OneToMany, JoinColumn } from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { Bundle } from '../../lineman/entities/bundle.entity';

export enum POStatus {
  NEW = 'NEW',
  IN_PROGRESS = 'IN_PROGRESS',
  COMPLETED = 'COMPLETED',
}

@Entity('production_orders')
export class ProductionOrder {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  article_no: string;

  @Column({ type: 'decimal', precision: 10, scale: 2 })
  piece_rate: number;

  @Column({ type: 'int' })
  total_quantity: number;

  @Column({
    type: 'enum',
    enum: POStatus,
    default: POStatus.NEW,
  })
  status: POStatus;

  @ManyToOne(() => User, { nullable: true })
  @JoinColumn({ name: 'assigned_lineman_id' })
  assignedLineman: User;

  @OneToMany(() => Bundle, (bundle) => bundle.productionOrder)
  bundles: Bundle[];

  @CreateDateColumn()
  created_at: Date;

  @UpdateDateColumn()
  updated_at: Date;
}
